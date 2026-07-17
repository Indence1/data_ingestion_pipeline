# Use official lightweight Python image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8080

# Set working directory
WORKDIR /app

# Install system dependencies (lxml and sqlite requirements)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libxml2-dev \
    libxslt-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy dependency list and install them
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Copy the config.yaml.example to config.yaml if config.yaml doesn't exist
# (This allows the container to run immediately using environment variables)
RUN cp config.yaml.example config.yaml

# Expose the port
EXPOSE 8080

# Create a mount point for persistent data storage (SQLite db, XMLs, JSONs, checkpoints)
VOLUME ["/app/data"]

# Start the dashboard application
CMD ["python", "dashboard/app.py"]
