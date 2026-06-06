# ==========================================
# Phase 1: Base Runtime Environment
# ==========================================
FROM python:3.11-slim
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /app

# ==========================================
# Phase 2: Security Hardening & User Setup
# ==========================================
RUN groupadd --system appgroup && \
    useradd --system --gid appgroup --create-home appuser

# ==========================================
# Phase 3: Dependency Resolution & Layer Caching
# ==========================================
COPY app/requirements.txt .

# PATCH: Explicitly upgrading pip, setuptools, and wheel to remediate CVE-2026-24049 & CVE-2026-23949
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# ==========================================
# Phase 4: Code Transfer & Privilege Revocation
# ==========================================
COPY app/ ./app
RUN chown -R appuser:appgroup /app
USER appuser
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
