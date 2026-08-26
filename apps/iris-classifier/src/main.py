"""Minimal, easy-to-read FastAPI service serving a scikit-learn Iris classifier.

Which model version (v1/v2) is loaded is decided purely by the MODEL_VERSION env var,
so the exact same container image is reused for both Deployments in the Helm chart —
only the env var and the Kubernetes labels differ between them.
"""
import json
import os
import pathlib
import time

import joblib
from fastapi import FastAPI, Response
from fastapi.responses import HTMLResponse
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from pydantic import BaseModel, Field

MODEL_VERSION = os.getenv("MODEL_VERSION", "v1")
MODEL_NAMES = {"v1": "LogisticRegression", "v2": "RandomForestClassifier"}

BASE_DIR = pathlib.Path(__file__).parent
model = joblib.load(BASE_DIR / "models" / f"{MODEL_VERSION}.joblib")
meta = json.loads((BASE_DIR / "models" / "meta.json").read_text())
TARGET_NAMES = meta["target_names"]

app = FastAPI(title="iris-classifier", version=MODEL_VERSION)

PREDICTIONS_TOTAL = Counter(
    "iris_predictions_total", "Predictions served", ["model_version", "predicted_class"]
)
REQUEST_LATENCY = Histogram(
    "iris_request_latency_seconds", "Request latency", ["path"]
)


class IrisInput(BaseModel):
    sepal_length: float = Field(..., ge=0, le=15)
    sepal_width: float = Field(..., ge=0, le=15)
    petal_length: float = Field(..., ge=0, le=15)
    petal_width: float = Field(..., ge=0, le=15)


class IrisPrediction(BaseModel):
    species: str
    confidence: float
    probabilities: dict[str, float]
    model_version: str
    model_type: str


@app.get("/", response_class=HTMLResponse)
def index() -> str:
    return (BASE_DIR / "static" / "index.html").read_text()


@app.get("/healthz")
def healthz() -> dict:
    return {"status": "ok", "model_version": MODEL_VERSION}


@app.post("/predict", response_model=IrisPrediction)
def predict(payload: IrisInput) -> IrisPrediction:
    start = time.perf_counter()
    features = [[
        payload.sepal_length,
        payload.sepal_width,
        payload.petal_length,
        payload.petal_width,
    ]]
    probabilities = model.predict_proba(features)[0]
    predicted_idx = int(probabilities.argmax())
    species = TARGET_NAMES[predicted_idx]

    PREDICTIONS_TOTAL.labels(model_version=MODEL_VERSION, predicted_class=species).inc()
    REQUEST_LATENCY.labels(path="/predict").observe(time.perf_counter() - start)

    return IrisPrediction(
        species=species,
        confidence=float(probabilities[predicted_idx]),
        probabilities=dict(zip(TARGET_NAMES, (float(p) for p in probabilities))),
        model_version=MODEL_VERSION,
        model_type=MODEL_NAMES[MODEL_VERSION],
    )


@app.get("/metrics")
def metrics() -> Response:
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
