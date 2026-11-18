
import uuid
import numpy as np
import pandas as pd


START_DATE = "2021-01-01"
END_DATE = "2026-01-01"  # Exclusive


def generate_room_nights():

    print("Loading source datasets...")

    rooms = pd.read_csv("data/raw/rooms.csv")
    stays = pd.read_csv("data/raw/stays.csv")
    reservations = pd.read_csv("data/raw/reservations.csv")

    stays["actual_checkin"] = pd.to_datetime(stays["actual_checkin"])
    stays["actual_checkout"] = pd.to_datetime(stays["actual_checkout"])

    # Attach the nightly rate to each actual stay.
    stays = stays.merge(
        reservations[["reservation_id", "quoted_nightly_rate"]],
        on="reservation_id",
        how="left"
    )

    print("Generating room-date combinations...")

    dates = pd.date_range(
        start=START_DATE,
        end=END_DATE,
        inclusive="left"
    )

    # One record for every room on every calendar date.
    room_nights = pd.DataFrame({
        "room_id": np.repeat(rooms["room_id"].values, len(dates)),
        "business_date": np.tile(dates.values, len(rooms))
    })

    room_nights = room_nights.merge(
        rooms[["room_id", "room_status"]],
        on="room_id",
        how="left"
    )

    # Only active rooms are available for sale.
    room_nights["is_available"] = (
        room_nights["room_status"] == "ACTIVE"
    )

    room_nights.drop(columns=["room_status"], inplace=True)

    print("Expanding stays into occupied room nights...")

    # Calculate the number of occupied nights for each stay.
    nights_per_stay = (
        stays["actual_checkout"] - stays["actual_checkin"]
    ).dt.days

    expanded_stays = stays.loc[
        stays.index.repeat(nights_per_stay)
    ].copy()

    # Generate each individual business date.
    expanded_stays["night_number"] = (
        expanded_stays.groupby(level=0).cumcount()
    )

    expanded_stays["business_date"] = (
        expanded_stays["actual_checkin"]
        + pd.to_timedelta(expanded_stays["night_number"], unit="D")
    )

    occupied_nights = expanded_stays[
        [
            "room_id",
            "stay_id",
            "business_date",
            "quoted_nightly_rate"
        ]
    ].reset_index(drop=True)

    # Match occupied nights to the complete room-date dataset.
    room_nights = room_nights.merge(
        occupied_nights,
        on=["room_id", "business_date"],
        how="left"
    )

    room_nights["is_occupied"] = room_nights["stay_id"].notna()

    room_nights["room_revenue"] = np.where(
        room_nights["is_occupied"],
        room_nights["quoted_nightly_rate"],
        0
    )

    # Unavailable rooms cannot be occupied.
    if (
        room_nights["is_occupied"] &
        ~room_nights["is_available"]
    ).any():
        raise ValueError("Found occupied nights in unavailable rooms.")

    # Add primary keys.
    room_nights.insert(
        0,
        "room_night_id",
        [str(uuid.uuid4()) for _ in range(len(room_nights))]
    )

    room_nights["room_revenue"] = (
        room_nights["room_revenue"].round(2)
    )

    room_nights["business_date"] = (
        room_nights["business_date"].dt.strftime("%Y-%m-%d")
    )

    room_nights["is_available"] = (
        room_nights["is_available"].astype(bool)
    )

    room_nights["is_occupied"] = (
        room_nights["is_occupied"].astype(bool)
    )

    room_nights.drop(
        columns=["quoted_nightly_rate"],
        inplace=True
    )

    room_nights.to_csv(
        "data/raw/room_nights.csv",
        index=False
    )

    print("\nROOM NIGHT GENERATION SUMMARY")
    print("=" * 45)
    print("Total room-night records:", len(room_nights))
    print("Available room nights:", room_nights["is_available"].sum())
    print("Occupied room nights:", room_nights["is_occupied"].sum())
    print(
        "Unoccupied available nights:",
        (
            room_nights["is_available"] &
            ~room_nights["is_occupied"]
        ).sum()
    )
    print(
        "Unavailable room nights:",
        (~room_nights["is_available"]).sum()
    )
    print(
        "Total room revenue:",
        round(room_nights["room_revenue"].sum(), 2)
    )
    print("=" * 45)

    print("\nSaved: data/raw/room_nights.csv")


if __name__ == "__main__":
    generate_room_nights()
