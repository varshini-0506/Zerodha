# Combined Dockerfile - Chromium + chromedriver verification + production gunicorn
FROM python:3.11-slim

# Basic env vars
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMEDRIVER_PATH=/usr/lib/chromium/chromedriver
ENV PATH="$PATH:/root/.local/bin"

WORKDIR /app

# Install chromium, chromedriver and required libs for headless chrome
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    chromium \
    chromium-driver \
    ca-certificates wget curl gnupg unzip \
    fonts-liberation libnss3 libxss1 libasound2 \
    libatk1.0-0 libatk-bridge2.0-0 libcups2 libxrandr2 \
    libxcomposite1 libxdamage1 libxfixes3 libxcursor1 libxtst6 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user BEFORE setting permissions
RUN useradd -m -u 1000 appuser

# Fix ChromeDriver permissions for non-root user

#RUN chmod +x /usr/lib/chromium/chromedriver && \
#    chown appuser:appuser /usr/lib/chromium/chromedriver && \
#    chmod +x /usr/bin/chromium && \
#    chown appuser:appuser /usr/bin/chromium

RUN chmod +x /usr/bin/chromedriver && chown appuser:appuser /usr/bin/chromedriver && \
    chmod +x /usr/bin/chromium && chown appuser:appuser /usr/bin/chromium


# Make symlinks for compatibility and ensure they're owned by appuser
RUN ln -sf /usr/bin/chromium /usr/bin/google-chrome && \
    ln -sf /usr/lib/chromium/chromedriver /usr/local/bin/chromedriver && \
    chown -h appuser:appuser /usr/bin/google-chrome /usr/local/bin/chromedriver

# Copy only requirements first for layer caching
COPY requirements.txt /app/requirements.txt

# Install Python deps
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r /app/requirements.txt

# Copy application code and set ownership
COPY . /app/
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose an informational port
EXPOSE 10000

# Optional healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f "http://localhost:${PORT:-5000}/health" || exit 1

# Final command
CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT} app:app --workers 2 --threads 2"]
