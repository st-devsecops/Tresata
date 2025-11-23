FROM tiangolo/uvicorn-gunicorn-fastapi:python3.11

# Install redis client once and for all
RUN pip install --no-cache-dir redis==5.1.1

# Our voting app
COPY main.py /app/main.py