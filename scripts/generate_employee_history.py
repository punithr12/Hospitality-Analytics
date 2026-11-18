
import uuid
import random
import numpy as np
import pandas as pd

random.seed(42)
np.random.seed(42)

START_DATE = pd.Timestamp("2021-01-01")
END_DATE = pd.Timestamp("2025-12-31")

DEPARTMENTS = [
    "Front Office",
    "Housekeeping",
    "Food & Beverage",
    "Maintenance",
    "Sales & Marketing",
    "Finance",
    "Human Resources"
]

POSITIONS = {
    "Front Office": ["Receptionist", "Front Office Executive", "Manager"],
    "Housekeeping": ["Room Attendant", "Housekeeping Executive", "Supervisor"],
    "Food & Beverage": ["Waiter", "Chef", "Restaurant Manager"],
    "Maintenance": ["Technician", "Maintenance Executive", "Supervisor"],
    "Sales & Marketing": ["Sales Executive", "Marketing Executive", "Manager"],
    "Finance": ["Accountant", "Finance Executive", "Manager"],
    "Human Resources": ["HR Executive", "Recruiter", "HR Manager"]
}

EXIT_TYPES = [
    "RESIGNATION",
    "TERMINATION",
    "RETIREMENT",
    "TRANSFER",
    "CONTRACT_END",
    "OTHER"
]

EXIT_PROBABILITIES = [0.55, 0.15, 0.05, 0.10, 0.10, 0.05]


def random_date(start, end):
    days = (end - start).days
    return start + pd.Timedelta(days=random.randint(0, max(days, 0)))


def generate_employee_history():

    print("Loading employee and hotel datasets...")

    employees = pd.read_csv("data/raw/employees.csv")
    hotels = pd.read_csv("data/raw/hotels.csv")

    history = []

    for _, employee in employees.iterrows():

        # Some employees joined before the reporting period.
        employment_start = random_date(
            START_DATE - pd.Timedelta(days=730),
            START_DATE + pd.Timedelta(days=365)
        )

        first_hotel = random.choice(hotels["hotel_id"].tolist())

        department = random.choice(DEPARTMENTS)
        position = random.choice(POSITIONS[department])

        current_start = employment_start
        current_hotel = first_hotel

        # Decide whether this employee has an employment event
        # during the five-year reporting period.
        has_exit = random.random() < 0.32

        if has_exit:
            exit_date = random_date(
                max(current_start, START_DATE),
                END_DATE
            )

            exit_type = random.choices(
                EXIT_TYPES,
                weights=EXIT_PROBABILITIES,
                k=1
            )[0]

            # Record the first employment period.
            history.append({
                "employment_history_id": str(uuid.uuid4()),
                "employee_id": employee["employee_id"],
                "hotel_id": current_hotel,
                "position": position,
                "department": department,
                "employment_type": random.choice(
                    ["FULL_TIME", "CONTRACT", "PART_TIME"]
                ),
                "start_date": current_start.strftime("%Y-%m-%d"),
                "end_date": exit_date.strftime("%Y-%m-%d"),
                "exit_type": exit_type,
                "exit_reason": (
                    "Internal hotel transfer"
                    if exit_type == "TRANSFER"
                    else random.choice([
                        "Personal reasons",
                        "Career growth",
                        "Performance issues",
                        "Retirement",
                        "Contract completed",
                        "Other"
                    ])
                )
            })

            # Transfers create a new employment period,
            # but do not represent an organizational exit.
            if exit_type == "TRANSFER":

                new_hotel = random.choice(
                    [h for h in hotels["hotel_id"].tolist()
                     if h != current_hotel]
                )

                new_start = exit_date + pd.Timedelta(days=1)

                history.append({
                    "employment_history_id": str(uuid.uuid4()),
                    "employee_id": employee["employee_id"],
                    "hotel_id": new_hotel,
                    "position": position,
                    "department": department,
                    "employment_type": random.choice(
                        ["FULL_TIME", "CONTRACT", "PART_TIME"]
                    ),
                    "start_date": new_start.strftime("%Y-%m-%d"),
                    "end_date": None,
                    "exit_type": None,
                    "exit_reason": None
                })

        else:
            # Employees without exits remain employed.
            history.append({
                "employment_history_id": str(uuid.uuid4()),
                "employee_id": employee["employee_id"],
                "hotel_id": current_hotel,
                "position": position,
                "department": department,
                "employment_type": random.choice(
                    ["FULL_TIME", "CONTRACT", "PART_TIME"]
                ),
                "start_date": current_start.strftime("%Y-%m-%d"),
                "end_date": None,
                "exit_type": None,
                "exit_reason": None
            })

    employee_history = pd.DataFrame(history)

    employee_history.to_csv(
        "data/raw/employee_history.csv",
        index=False
    )

    print("\nEMPLOYEE HISTORY GENERATION SUMMARY")
    print("=" * 50)
    print("Total Employees:", employees["employee_id"].nunique())
    print("Employment History Records:", len(employee_history))
    print(
        "Employees with multiple periods:",
        (employee_history.groupby("employee_id").size() > 1).sum()
    )
    print(
        "Employees with exit records:",
        employee_history["exit_type"].notna().sum()
    )
    print(
        "Internal Transfers:",
        (employee_history["exit_type"] == "TRANSFER").sum()
    )
    print(
        "Active Employment Records:",
        employee_history["end_date"].isna().sum()
    )
    print("=" * 50)
    print("Saved: data/raw/employee_history.csv")


if __name__ == "__main__":
    generate_employee_history()
