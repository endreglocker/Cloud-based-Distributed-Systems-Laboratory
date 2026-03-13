FROM python:3.14-rc-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY image_viewer/requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY image_viewer/ .

RUN python manage.py collectstatic --noinput

EXPOSE 8000

CMD ["sh", "-c", "python manage.py migrate && gunicorn image_viewer.wsgi:application --bind 0.0.0.0:8000 --workers 2"]