# 1. Use the bleeding edge Python 3.13
FROM python:3.13-slim

# 2. Set environment variables (Fixed syntax with '=')
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 3. Install System Video Tools (FFmpeg)
# We need this because Python 3.13 is minimal and doesn't have video tools built-in
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsm6 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

# 4. Set work directory
WORKDIR /app

# 5. Install dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# 6. Copy project
COPY . /app/

# 7. Run the server
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]