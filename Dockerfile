# ==========================================
# STAGE 1: COMPILATION & BUILD CONTEXT
# ==========================================
FROM python:3.11-slim AS builder

WORKDIR /workspace

# Force an explicit operating system patch run during compilation
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv /workspace/venv
ENV PATH="/workspace/venv/bin:$PATH"

COPY requirements.txt .

# REMEDIATION CRITICAL: Ensure base installation components are modern and clean
RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

# ==========================================
# STAGE 2: HARDENED RUNTIME DISTROLESS LAYER
# ==========================================
FROM gcr.io/distroless/python3-debian12

WORKDIR /app

COPY --from=builder /workspace/venv /workspace/venv
COPY ./app /app/app

ENV PATH="/workspace/venv/bin:$PATH"
ENV PYTHONPATH="/workspace/venv/lib/python3.11/site-packages"

EXPOSE 8080

ENTRYPOINT ["/workspace/venv/bin/uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]