import os
import time
from flask import Flask, jsonify

app = Flask(__name__)

START_TIME = time.time()
VERSION = os.environ.get("APP_VERSION", "1.0.0")
REQUEST_COUNT = 0


@app.route("/")
def home():
    global REQUEST_COUNT
    REQUEST_COUNT += 1
    return jsonify(
        message="Hello from the HSBC onboarding lab app",
        version=VERSION,
        pod=os.environ.get("HOSTNAME", "local"),
    )


@app.route("/healthz")
def healthz():
    return jsonify(status="ok"), 200


@app.route("/readyz")
def readyz():
    # Simulate a real readiness check by requiring the app to have been up 3s
    if time.time() - START_TIME < 3:
        return jsonify(status="warming up"), 503
    return jsonify(status="ready"), 200


@app.route("/metrics")
def metrics():
    uptime = round(time.time() - START_TIME, 2)
    return (
        f"app_uptime_seconds {uptime}\n"
        f"app_request_count {REQUEST_COUNT}\n"
        f"app_version_info{{version=\"{VERSION}\"}} 1\n"
    ), 200, {"Content-Type": "text/plain"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
