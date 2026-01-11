# Secure Dockerfile with security best practices
# Multi-stage build for smaller, more secure images

# Build stage
FROM python:3.11-slim AS builder

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY app/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.11-slim

# Metadata
LABEL maintainer="devsecops-demo" \
      version="2.0.0" \
      description="Secure FastAPI application"

# Set working directory
WORKDIR /app

# FIXED: Create non-root user
RUN groupadd -r appuser && useradd --no-log-init -r -g appuser appuser

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY --chown=appuser:appuser app/ .

# Create necessary directories with proper permissions
RUN mkdir -p /app/data /tmp && \
    chown -R appuser:appuser /app /tmp

# FIXED: Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# FIXED: Add HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# FIXED: Use exec form instead of shell form
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]

# Security improvements:
# 1. Multi-stage build reduces image size and attack surface
# 2. Running as non-root user (appuser)
# 3. HEALTHCHECK for container health monitoring
# 4. Minimal base image (python:3.11-slim)
# 5. No unnecessary packages installed
# 6. Proper file permissions
# 7. Exec form CMD for proper signal handling
# 8. Latest Python version with security patches
