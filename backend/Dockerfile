# 1. Use the bleeding edge Python 3.13
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# 🛠️ FIX: Install system dependencies for psycopg2 and general build tools
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    python3-dev \
    musl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# 🚀 PROD OVERRIDE: Dummy DB URL to prevent collectstatic from crashing
RUN DATABASE_URL=postgres://none:none@none/none python manage.py collectstatic --noinput

# Run using Gunicorn
CMD exec gunicorn --bind 0.0.0.0:$PORT --workers 1 --threads 8 --timeout 0 core.wsgi:application