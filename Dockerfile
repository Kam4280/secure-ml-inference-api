# ==========================================
# Phase 1: Base Runtime Environment
# ==========================================
# Using a slim Debian-based Python image to minimize the container's attack surface area
FROM python:3.11-slim

# Prevent Python from writing .pyc bytecode files to disk (reduces container bloat)
ENV PYTHONDONTWRITEBYTECODE=1

# Force Python outputs (stdout/stderr) to be unbuffered so logs appear immediately in Cloud Logging/Stackdriver
ENV PYTHONUNBUFFERED=1

# Establish the secure application directory inside the container
WORKDIR /app

# ==========================================
# Phase 2: Security Hardening & User Setup
# ==========================================
# Create an isolated system group and a non-root system user with no login shell or root access
RUN groupadd --system appgroup && \
    useradd --system --gid appgroup --create-home appuser

# ==========================================
# Phase 3: Dependency Resolution & Layer Caching
# ==========================================
# Copy ONLY the requirements file first. This optimizes Docker's layer caching engine.
# If requirements.txt doesn't change, Docker skips the slow pip installation step on subsequent builds.
COPY app/requirements.txt .

# Upgrade pip and install pinned python libraries without caching the installer files locally
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ==========================================
# Phase 4: Code Transfer & Privilege Revocation
# ==========================================
# Copy the actual application source code into the container
COPY app/ ./app

# Explicitly change file ownership of the /app space from root to our unprivileged user
RUN chown -R appuser:appgroup /app

# Switch the container execution state from root to the unprivileged appuser
USER appuser

# Expose port 8000 to match our internal application binding
EXPOSE 8000

# Execute the FastAPI engine via the Uvicorn web server using the explicit JSON array syntax
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
