# Dockerfile with intentional security issues for DevSecOps demo
# WARNING: Contains security vulnerabilities for educational purposes only

# Using an older base image that may contain CVEs
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY app/requirements.txt .

# Install dependencies
# ISSUE: No pinned versions in pip, setuptools, wheel
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ .

# MISCONFIGURATION 1: Running as root user (no USER directive)
# Should add: RUN adduser --disabled-password --gecos '' appuser
# Should add: USER appuser

# MISCONFIGURATION 2: No HEALTHCHECK defined
# Should add: HEALTHCHECK CMD curl --fail http://localhost:8000/health || exit 1

# Expose port
EXPOSE 8000

# MISCONFIGURATION 3: Using shell form instead of exec form
# Should use: CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
CMD uvicorn main:app --host 0.0.0.0 --port 8000

# Additional issues that Trivy will detect:
# - Base image (python:3.9-slim) may contain known CVEs
# - Vulnerable dependencies in requirements.txt
# - No security scanning in build process
# - No image signing
# - No SBOM generation
