# FieldPulse

FieldPulse is a full-stack field service management application built with Django (Backend) and Flutter (Mobile App).

## Prerequisites

- Docker and docker-compose
- Flutter SDK (for running the mobile app locally)

## How to Run the Project

### Backend

The backend runs using Docker. It includes the Django web application, a PostgreSQL database, and MinIO for S3-compatible file storage.

1. Navigate to the `backend` directory:
   ```bash
   cd backend
   ```
2. Build and start the services using docker-compose:
   ```bash
   docker-compose up --build
   ```
   The API will be available at `http://localhost:8000/`. The admin panel is at `http://localhost:8000/admin/`. MinIO console is available at `http://localhost:9001/` (Credentials: minioadmin / minioadmin).

### Mobile

1. Navigate to the `mobile/fieldpulse` directory:
   ```bash
   cd mobile/fieldpulse
   ```
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app on a connected device or emulator:
   ```bash
   flutter run
   ```

## How to Run Tests

### Backend Tests

The backend uses Django's built-in testing framework. You can execute them inside the running Docker container.

Using Docker:

```bash
docker-compose exec web python manage.py test tests --verbosity=2
```

### Mobile Tests

The mobile app uses Flutter's test runner for both unit/widget tests and integration tests.

To run unit and widget tests:

```bash
cd mobile/fieldpulse
flutter test
```

To run integration tests (requires a running emulator or connected device):

```bash
flutter test integration_test/app_test.dart
```

## Performance Profiling

The job list maintains 60fps scrolling with 500+ jobs. Below is a profile screenshot from Flutter DevTools showing consistent frame rendering.

![Performance Profile](docs/performance-profile.png)

## Test Account (seeded automatically)

Email: tech@fieldpulse.com
Password: Tech123!
Role: Technician

## Known Limitations and Incomplete Features

- **Push Notifications:** Fully remote push notifications (e.g., via APNs or FCM) are not fully implemented. Local notifications or basic foreground alerting might be used to simulate this behavior.
- **Advanced Dynamic Checklist Fields:** While the backend supports storing complex JSON schemas for checklists, the mobile UI currently prioritizes the core fields (text, checkbox). More complex interactions like dependent fields or advanced validation rules are simplified.
- **Advanced Conflict UI:** If a job is modified on the server while the technician is offline, the app relies on versioning to prevent data loss, but does not yet feature a detailed side-by-side merge UI for resolving complex text conflicts manually.
- **End-to-End Test Automation:** While an integration test suite is set up to verify the core flows (Login -> Job List -> Detail), it may not cover every single edge case across all offline state transitions.
