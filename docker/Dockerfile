# syntax=docker/dockerfile:1

FROM python:3.12-slim AS build
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir --target=/install -r requirements.txt

FROM python:3.12-slim AS runtime
ENV PYTHONUNBUFFERED=1 \
    PATH=/install/bin:$PATH \
    PYTHONPATH=/install

RUN groupadd --gid 1001 appgroup \
    && useradd --uid 1001 --gid appgroup --shell /usr/sbin/nologin --create-home appuser

WORKDIR /app
COPY --from=build /install /install
COPY --chown=appuser:appgroup app/app.py .

USER appuser
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD python -c "import urllib.request;urllib.request.urlopen('http://127.0.0.1:8080/healthz')" || exit 1

CMD ["gunicorn", "-b", "0.0.0.0:8080", "app:app"]
