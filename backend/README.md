# FieldPulse Backend

This is the backend service for the FieldPulse mobile job management application. It provides a REST API built with Django and Django REST Framework, utilizing PostgreSQL for data storage and MinIO (S3-compatible) for file/photo storage.

## Prerequisites

- [Python 3.10+](https://www.python.org/downloads/)
- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- Virtual Environment module

## Local Setup

### 1. Clone & Navigate
Navigate into the backend directory:
```bash
cd path/to/fieldpulse/backend
```

### 2. Environment Variables
Create a `.env` file based on the provided example:
```bash
cp .env.example .env
```

### 3. Docker Services (PostgreSQL & MinIO)
Start the local database and object storage using Docker Compose:
```bash
docker-compose up -d
```
This will spin up:
- **PostgreSQL** on port `5432`
- **MinIO** on port `9000` (API) and `9001` (Console)

### 4. Python Environment & Dependencies
Create and activate your virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate
```

Install the dependencies:
```bash
pip install -r requirements.txt
```

### 5. Database Migrations
Run Django migrations to set up the database schema:
```bash
python manage.py migrate
```

### 6. Seeding the Database
To generate sample jobs and users with realistic data for testing:
```bash
# Assuming a custom management command is implemented
python manage.py seed
```

## Running the Server

Start the Django development server:
```bash
python manage.py runserver
```
The API will be accessible at `http://127.0.0.1:8000/`.

## Accessing MinIO

You can view uploaded photos, signatures, and files by accessing the MinIO web console:
- **URL**: `http://127.0.0.1:9001/`
- **Username**: `minioadmin`
- **Password**: `minioadmin`

## Testing

To run the automated tests:
```bash
python manage.py test
```

## Known Limitations & Architecture

Please refer to the `DECISIONS.md` file (if present) for detailed context on offline sync approaches, database design choices, and known limitations.
