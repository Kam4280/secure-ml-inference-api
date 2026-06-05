# ==========================================
# STAGE 1: COMPILATION & BUILD CONTEXT
# ==========================================
FROM python:3.11-slim AS builder

WORKDIR /workspace

# Install essential compilation tools cleanly
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Compile dependencies directly into a localized virtual environment
RUN python -m venv /workspace/venv
ENV PATH="/workspace/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ==========================================
# STAGE 2: HARDENED RUNTIME DISTROLESS LAYER
# ==========================================
# Google's Distroless images contain ONLY your application and its runtime. 
# They do NOT contain package managers (apt), shells (bash/sh), or debugging tools.
FROM gcr.io/distroless/python3-debian12

WORKDIR /app

# Safely copy the isolated dependencies from stage 1
COPY --from=builder /workspace/venv /workspace/venv
COPY ./app /app/app

# Force runtime environment to prioritize our isolated execution layers
ENV PATH="/workspace/venv/bin:$PATH"
ENV PYTHONPATH="/workspace/venv/lib/python3.11/site-packages"

EXPOSE 8080

# Run using the production Uvicorn engine directly out of our environment
ENTRYPOINT ["/workspace/venv/bin/uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]