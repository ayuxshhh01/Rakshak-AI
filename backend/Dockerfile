FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONPATH=/app/backend:$PYTHONPATH

# Set the working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    default-libmysqlclient-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install backend dependencies first (for layer caching)
COPY req.txt .
RUN pip install --upgrade pip setuptools wheel && \
    pip install -r req.txt

# Copy project files
COPY . .

# Create directories for logs and static files
RUN mkdir -p /app/logs /app/staticfiles

# Verify the backend module exists
RUN test -f /app/backend/backend/__init__.py || (echo "ERROR: backend module not found!" && exit 1)
RUN test -f /app/backend/manage.py || (echo "ERROR: manage.py not found!" && exit 1)

EXPOSE 8000

# Default command - can be overridden by docker-compose
CMD ["daphne", "-b", "0.0.0.0", "-p", "8000", "backend.asgi:application"]
