
import pandas as pd
import numpy as np
import uuid
import random

from faker import Faker
from datetime import date, datetime, timedelta

fake = Faker("en_IN")

# Reproducibility
random.seed(42)
np.random.seed(42)
Faker.seed(42)


# ==========================================
# 1. HOTEL DATA GENERATION
# ==========================================

def generate_hotels():

    cities = [
        ("Bengaluru", "Karnataka"),
        ("Chennai", "Tamil Nadu"),
        ("Mumbai", "Maharashtra"),
        ("Delhi", "Delhi"),
        ("Goa", "Goa")
    ]

    hotels = []

    for city, state in cities:

        for i in range(1, 3):

            hotel = {
                "hotel_id": str(uuid.uuid4()),
                "hotel_name": f"{city} {random.choice(['Grand', 'Palace', 'Regency', 'Plaza', 'Suites'])} {i}",
                "city": city,
                "state": state,
                "country": "India",
                "star_rating": random.choice([3.0, 3.5, 4.0, 4.5, 5.0]),
                "opened_on": fake.date_between(
                    start_date="-15y",
                    end_date="-5y"
                )
            }

            hotels.append(hotel)

    return pd.DataFrame(hotels)


# ==========================================
# 2. ROOM DATA GENERATION
# ==========================================

def generate_rooms(hotels):

    room_types = {
        "Standard": 2500,
        "Deluxe": 4000,
        "Suite": 7000,
        "Executive": 5500
    }

    rooms = []

    for _, hotel in hotels.iterrows():

        for room_number in range(101, 201):

            room_type = random.choice(list(room_types.keys()))

            base_rate = room_types[room_type]

            room = {
                "room_id": str(uuid.uuid4()),
                "hotel_id": hotel["hotel_id"],
                "room_number": str(room_number),
                "room_type": room_type,
                "max_occupancy": random.choice([1, 2, 2, 3, 4]),
                "base_rate": base_rate * random.uniform(0.90, 1.15),
                "room_status": random.choices(
                    ["ACTIVE", "MAINTENANCE", "INACTIVE"],
                    weights=[94, 4, 2]
                )[0]
            }

            rooms.append(room)

    return pd.DataFrame(rooms)

# ==========================================
# 3. GUEST DATA GENERATION
# ==========================================

def generate_guests(n=20000):

    guests = []

    for _ in range(n):

        first_name = fake.first_name()
        last_name = fake.last_name()

        guest = {
            "guest_id": str(uuid.uuid4()),
            "first_name": first_name,
            "last_name": last_name,
            "email": fake.unique.email(),
            "phone": fake.phone_number()[:20],
            "gender": random.choice(["Male", "Female", "Other"]),
            "date_of_birth": fake.date_of_birth(
                minimum_age=18,
                maximum_age=75
            ),
            "home_city": random.choice([
                "Bengaluru",
                "Chennai",
                "Mumbai",
                "Delhi",
                "Goa",
                "Hyderabad",
                "Pune",
                "Kochi"
            ])
        }

        guests.append(guest)

    return pd.DataFrame(guests)


# ==========================================
# 4. EMPLOYEE DATA GENERATION
# ==========================================

def generate_employees(n=750):

    employees = []

    for _ in range(n):

        first_name = fake.first_name()
        last_name = fake.last_name()

        employee = {
            "employee_id": str(uuid.uuid4()),
            "first_name": first_name,
            "last_name": last_name,
            "email": fake.unique.email(),
            "phone": fake.phone_number()[:20],
            "gender": random.choice(["Male", "Female", "Other"])
        }

        employees.append(employee)

    return pd.DataFrame(employees)

# ==========================================
# 5. SEASONAL BUSINESS CONFIGURATION
# ==========================================

OCCUPANCY_TARGETS = {
    1: 0.55,
    2: 0.58,
    3: 0.62,
    4: 0.68,
    5: 0.82,
    6: 0.78,
    7: 0.48,
    8: 0.50,
    9: 0.58,
    10: 0.72,
    11: 0.82,
    12: 0.90
}

PRICE_MULTIPLIERS = {
    1: 1.00,
    2: 1.00,
    3: 1.05,
    4: 1.10,
    5: 1.25,
    6: 1.20,
    7: 0.85,
    8: 0.85,
    9: 0.95,
    10: 1.10,
    11: 1.20,
    12: 1.35
}


# ==========================================
# 6. RESERVATION AND STAY GENERATION
# ==========================================

def generate_reservations_and_stays(rooms, guests):

    start_date = date(2021, 1, 1)
    end_date = date(2025, 12, 31)

    guest_ids = guests["guest_id"].tolist()

    reservation_columns = [
        "reservation_id",
        "guest_id",
        "room_id",
        "booking_date",
        "planned_checkin",
        "planned_checkout",
        "booking_channel",
        "quoted_nightly_rate",
        "status"
    ]

    stay_columns = [
        "stay_id",
        "reservation_id",
        "room_id",
        "actual_checkin",
        "actual_checkout",
        "stay_status"
    ]

    reservation_rows = []
    stay_rows = []

    active_rooms = rooms[
        rooms["room_status"] == "ACTIVE"
    ]

    print("\nGenerating completed reservations and stays...")

    # --------------------------------------
    # Generate actual room occupancy
    # --------------------------------------

    for _, room in active_rooms.iterrows():

        room_id = room["room_id"]
        base_rate = float(room["base_rate"])

        current_date = start_date

        while current_date <= end_date:

            month = current_date.month

            occupancy_target = OCCUPANCY_TARGETS[month]

            average_stay = 3

            # Probability of starting a booking
            start_probability = (
                occupancy_target /
                (
                    average_stay * (1 - occupancy_target)
                    + occupancy_target
                )
            )

            if random.random() < start_probability:

                stay_length = random.choice([2, 3, 4])

                checkout_date = min(
                    current_date + timedelta(days=stay_length),
                    end_date + timedelta(days=1)
                )

                booking_date = current_date - timedelta(
                    days=random.randint(1, 90)
                )

                reservation_id = str(uuid.uuid4())
                stay_id = str(uuid.uuid4())

                nightly_rate = round(
                    base_rate *
                    PRICE_MULTIPLIERS[month] *
                    random.uniform(0.90, 1.10),
                    2
                )

                reservation_rows.append((
                    reservation_id,
                    random.choice(guest_ids),
                    room_id,
                    booking_date,
                    current_date,
                    checkout_date,
                    random.choice([
                        "WEBSITE",
                        "WALK_IN",
                        "TRAVEL_AGENT",
                        "ONLINE_TRAVEL_AGENCY"
                    ]),
                    nightly_rate,
                    "COMPLETED"
                ))

                stay_rows.append((
                    stay_id,
                    reservation_id,
                    room_id,
                    current_date,
                    checkout_date,
                    "COMPLETED"
                ))

                # Move directly to checkout.
                # This prevents overlapping stays.
                current_date = checkout_date

            else:
                current_date += timedelta(days=1)

    completed_count = len(reservation_rows)

    print("Completed reservations:", completed_count)

    # --------------------------------------
    # Generate cancelled reservations
    # and no-show reservations
    # --------------------------------------

    print("Generating cancellations and no-shows...")

    non_stay_count = int(completed_count * 0.15)

    active_room_ids = active_rooms["room_id"].tolist()

    for _ in range(non_stay_count):

        room_id = random.choice(active_room_ids)

        guest_id = random.choice(guest_ids)

        checkin_date = fake.date_between_dates(
            date_start=start_date,
            date_end=end_date
        )

        checkout_date = checkin_date + timedelta(
            days=random.randint(1, 4)
        )

        booking_date = checkin_date - timedelta(
            days=random.randint(1, 90)
        )

        reservation_status = random.choices(
            ["CANCELLED", "NO_SHOW"],
            weights=[2, 1]
        )[0]

        room = rooms.loc[
            rooms["room_id"] == room_id
        ].iloc[0]

        base_rate = float(room["base_rate"])

        quoted_rate = round(
            base_rate *
            PRICE_MULTIPLIERS[checkin_date.month] *
            random.uniform(0.90, 1.10),
            2
        )

        reservation_rows.append((
            str(uuid.uuid4()),
            guest_id,
            room_id,
            booking_date,
            checkin_date,
            checkout_date,
            random.choice([
                "WEBSITE",
                "WALK_IN",
                "TRAVEL_AGENT",
                "ONLINE_TRAVEL_AGENCY"
            ]),
            quoted_rate,
            reservation_status
        ))

    # --------------------------------------
    # Convert to DataFrames
    # --------------------------------------

    reservations_df = pd.DataFrame(
        reservation_rows,
        columns=reservation_columns
    )

    stays_df = pd.DataFrame(
        stay_rows,
        columns=stay_columns
    )

    return reservations_df, stays_df




# ==========================================
# 3. MAIN EXECUTION
# ==========================================

if __name__ == "__main__":

    print("Starting Hospitality Data Generation...")

    hotels_df = generate_hotels()

    rooms_df = generate_rooms(hotels_df)

    # Save datasets
    hotels_df.to_csv("data/raw/hotels.csv", index=False)

    rooms_df.to_csv("data/raw/rooms.csv", index=False)

    print("\nHotel Dataset Summary")
    print("---------------------")
    print("Total Hotels:", len(hotels_df))

    print("\nRoom Dataset Summary")
    print("--------------------")
    print("Total Rooms:", len(rooms_df))

    print("\nRooms by Category:")
    print(rooms_df["room_type"].value_counts())

    print("\nHotels by City:")
    print(hotels_df["city"].value_counts())

    print("\nData generation completed!")
    guests_df = generate_guests()

    employees_df = generate_employees()

    guests_df.to_csv("data/raw/guests.csv", index=False)

    employees_df.to_csv("data/raw/employees.csv", index=False)

    print("\nGuest Dataset Summary")
    print("Total Guests:", len(guests_df))

    print("\nEmployee Dataset Summary")
    print("Total Employees:", len(employees_df))
    reservations_df, stays_df = generate_reservations_and_stays(
    rooms_df,
    guests_df
)

    reservations_df.to_csv(
        "data/raw/reservations.csv",
        index=False
    )

    stays_df.to_csv(
        "data/raw/stays.csv",
        index=False
    )

    print("\nReservation Dataset Summary")
    print("----------------------------")
    print("Total Reservations:", len(reservations_df))

    print("\nReservation Status:")
    print(reservations_df["status"].value_counts())

    print("\nStay Dataset Summary")
    print("--------------------")
    print("Total Stays:", len(stays_df))