
import uuid
import random
import numpy as np
import pandas as pd
from datetime import datetime, timezone

# Reproducibility
random.seed(42)
np.random.seed(42)

FEEDBACK_RATE = 0.40

# Ratings are weighted to reflect generally positive hotel experiences.
RATING_PROBABILITIES = [0.03, 0.06, 0.16, 0.35, 0.40]

COMMENTS = {
    1: [
        "Very disappointing experience.",
        "The room was not properly maintained.",
        "Poor service and an uncomfortable stay."
    ],
    2: [
        "Service could have been much better.",
        "The facilities did not meet expectations.",
        "Some issues affected our stay."
    ],
    3: [
        "Average experience overall.",
        "The stay was satisfactory.",
        "Decent hotel, but there is room for improvement."
    ],
    4: [
        "Good experience and friendly staff.",
        "Comfortable stay with good service.",
        "Clean rooms and a pleasant experience."
    ],
    5: [
        "Excellent hospitality and outstanding service!",
        "Amazing stay. Would definitely visit again!",
        "Everything was perfect. Highly recommended!"
    ]
}


def generate_guest_feedback():

    print("Loading stay data...")

    stays = pd.read_csv("data/raw/stays.csv")

    stays["actual_checkout"] = pd.to_datetime(
        stays["actual_checkout"]
    )

    # Select 40% of completed stays for feedback.
    feedback_count = int(len(stays) * FEEDBACK_RATE)

    feedback_stays = stays.sample(
        n=feedback_count,
        random_state=42
    ).copy()

    print("Generating guest ratings...")

    ratings = []

    for _, stay in feedback_stays.iterrows():

        month = stay["actual_checkout"].month

        probabilities = RATING_PROBABILITIES.copy()

        # Slightly reduce top ratings during high-demand months.
        if month in [5, 11, 12]:
            probabilities[4] -= 0.04
            probabilities[2] += 0.02
            probabilities[3] += 0.02

        rating = np.random.choice(
            [1, 2, 3, 4, 5],
            p=probabilities
        )

        ratings.append(rating)

    feedback_stays["rating"] = ratings

    feedback_stays["comments"] = feedback_stays["rating"].apply(
        lambda rating: random.choice(COMMENTS[rating])
    )

    # Feedback is submitted between 1 and 7 days after checkout.
    feedback_stays["feedback_date"] = (
        feedback_stays["actual_checkout"]
        + pd.to_timedelta(
            np.random.randint(1, 8, size=len(feedback_stays)),
            unit="D"
        )
    )

    feedback_stays["feedback_id"] = [
        str(uuid.uuid4())
        for _ in range(len(feedback_stays))
    ]

    feedback_stays["created_at"] = datetime.now(
        timezone.utc
    ).isoformat()

    feedback = feedback_stays[
        [
            "feedback_id",
            "stay_id",
            "rating",
            "comments",
            "feedback_date",
            "created_at"
        ]
    ].copy()

    feedback["rating"] = feedback["rating"].astype(float)

    feedback["feedback_date"] = (
        feedback["feedback_date"].dt.strftime("%Y-%m-%d")
    )

    feedback.to_csv(
        "data/raw/guest_feedback.csv",
        index=False
    )

    print("\nGUEST FEEDBACK GENERATION SUMMARY")
    print("=" * 45)

    print("Total Completed Stays:", len(stays))
    print("Feedback Participation Rate:", f"{FEEDBACK_RATE * 100:.0f}%")
    print("Total Feedback Records:", len(feedback))

    print("\nRating Distribution:")
    print(feedback["rating"].value_counts().sort_index())

    print("\nAverage Guest Rating:",
          round(feedback["rating"].mean(), 2))

    print("\nSaved: data/raw/guest_feedback.csv")
    print("=" * 45)


if __name__ == "__main__":
    generate_guest_feedback()
