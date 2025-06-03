FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    procps \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN chmod +x examples/*.py
RUN mkdir -p uploads data logs

EXPOSE 5000

ENV FLASK_ENV=production
ENV HOST=0.0.0.0
ENV PORT=5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/system || exit 1

CMD ["python", "app.py"] 