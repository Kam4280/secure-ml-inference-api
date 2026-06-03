# ==========================================
# STAGE 1: COMPILATION & BUILD CONTEXT
# ==========================================
FROM python:3.11-slim AS builder

WORKDIR /workspace

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv /workspace/venv
ENV PATH="/workspace/venv/bin:$PATH"

COPY requirements.txt .

RUN pip install --no-cache-dir --upgrade pip setuptools wheel
RUN pip install --no-cache-dir -r requirements.txt

# ==========================================
# STAGE 2: HARDENED RUNTIME DISTROLESS/SLIM LAYER
# ==========================================
FROM python:3.11-slim

WORKDIR /app

# 1. Patch the base OS packages
RUN apt-get update && \
    apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# 2. REMEDIATION CRITICAL: Upgrade the global image tools to patch CVE-2026-23949 & CVE-2026-24049
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# 3. Copy your clean application context
COPY --from=builder /workspace/venv /workspace/venv
COPY ./app /app/app

ENV PATH="/workspace/venv/bin:$PATH"
ENV PYTHONPATH="/workspace/venv/lib/python3.11/site-packages"

EXPOSE 8080

# Hardening Step: Run as non-root user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

ENTRYPOINT ["/workspace/venv/bin/uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]