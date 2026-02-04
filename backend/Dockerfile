# backend/Dockerfile
FROM python:3.13-slim

# 1. Install System Tools (FFmpeg is the important one here)
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# 2. Create a folder inside the container
WORKDIR /app

# 3. Copy requirements FIRST (for caching speed)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. Copy the rest of the code
COPY . .

# 5. The default command (can be overridden by docker-compose)
CMD ["gunicorn", "core.wsgi:application", "--bind", "0.0.0.0:8000"]