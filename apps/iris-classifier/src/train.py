"""Trains two tiny models on the classic Iris dataset and bakes them into the image.

v1 = LogisticRegression (fast, linear, slightly less accurate)
v2 = RandomForestClassifier (slower, non-linear, slightly more accurate)

Having two versions of the *same* task is the whole point of the demo: it lets us
show Istio traffic-splitting / canary routing and compare both versions live in Kiali.
"""
import json
import pathlib

import joblib
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split

OUT_DIR = pathlib.Path(__file__).parent / "models"


def main() -> None:
    OUT_DIR.mkdir(exist_ok=True)
    data = load_iris()
    x_train, _, y_train, _ = train_test_split(
        data.data, data.target, test_size=0.2, random_state=42
    )

    v1 = LogisticRegression(max_iter=200).fit(x_train, y_train)
    v2 = RandomForestClassifier(n_estimators=100, random_state=42).fit(x_train, y_train)

    joblib.dump(v1, OUT_DIR / "v1.joblib")
    joblib.dump(v2, OUT_DIR / "v2.joblib")

    (OUT_DIR / "meta.json").write_text(
        json.dumps(
            {
                "feature_names": list(data.feature_names),
                "target_names": list(data.target_names),
            }
        )
    )
    print(f"models written to {OUT_DIR}")


if __name__ == "__main__":
    main()
