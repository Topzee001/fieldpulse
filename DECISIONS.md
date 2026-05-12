# Architectural Decisions and Trade-offs

## Mobile App Architecture

The Flutter app follows a feature-based MVVM-style architecture with the following structure:
- `src/app/providers`: app-level Riverpod providers and dependency injection
- `src/features/*`: feature modules (jobs, checklist, auth, etc.)
- `src/data/remote` + `src/data/local`: data layer for API clients, repositories, and local persistence
- `src/services`: background sync, notifications, and platform integration services
- `go_router` for navigation and `flutter_riverpod` for state management

The UI layers are implemented as Flutter widgets, while `StateNotifier`/`StateNotifierProvider` classes serve as the ViewModel layer, exposing state and actions to the views.

## State Management Approach

For the Flutter mobile application, I chose **Riverpod** for state management. 

**Why Riverpod?**
- **Compile-time safety:** Riverpod catches state-related errors at compile time rather than runtime.
- **Separation of concerns:** It enforces a clean separation between the UI and business logic, making the view models easy to test independently.
- **Asynchronous data handling:** With `AsyncValue`, Riverpod elegantly handles loading, data, and error states, which is crucial for an application that heavily relies on network requests and local database operations for its offline-first architecture.

**Trade-offs:** 
- There is a steeper learning curve compared to a simpler solution like `Provider` or `setState`.
- It requires slightly more boilerplate when defining providers, though this is a worthwhile trade-off for the scalability it provides.

## Offline Sync and Conflict Resolution

The application uses an **Offline-First** architecture to ensure technicians can operate seamlessly without an internet connection.

**How it works:**
1. **Local Storage First:** All job lists and updates are written to a local SQLite database (via `sqflite`) first. 
2. **Background Sync:** A sync queue manages pending API requests. When network connectivity is restored, the queue processes pending updates (e.g., status changes, checklist drafts) sequentially.

**Conflict Resolution:**
I implemented a **versioning/optimistic concurrency** system.
- Every `Job` model has a `version` field.
- When the mobile app fetches a job, it stores the current version.
- On update, the mobile app sends the version. If the server's version is higher, it means the job was updated by another client (e.g., a dispatcher). The server rejects the update or forces a re-sync.
- Currently, I use a basic version check, meaning last-write-wins from the backend perspective if version mismatches occur, forcing the client to pull the latest state to avoid silently overwriting data. 

**Trade-offs:** 
- A simple versioning system is reliable and relatively straightforward to implement, but it may overwrite user data if they attempt to edit a stale job. A more robust (but complex) solution would involve a detailed merge UI to handle field-level conflicts.

## Significant Architectural Decisions

1. **Django + DRF for Backend:** I chose this stack for its rapid API development capabilities. The Django ORM, combined with PostgreSQL, handles the dynamic JSON schemas required for the checklists (`JSONField`) extremely well.
2. **Repository Pattern in Mobile:** I abstracted API calls and local database operations behind repositories. This allows the UI and ViewModels to request data without needing to know if it came from the network or local cache.
3. **MinIO for Storage:** To simulate production S3-compatible storage locally, I integrated MinIO via Docker Compose. This ensures the photo and signature upload flows are tested against a real object storage paradigm, rather than just local disk storage.

## What I'd do differently with more time

1. **Background Syncing Mechanisms:** I would integrate a background processing package (like `workmanager`) so the app can silently retry uploading draft checklists, photos, or status changes when the device regains connectivity, even if the app has been terminated.
2. **Advanced Conflict Resolution UI:** Instead of relying solely on the underlying version check to reject stale data, I would implement a UI that alerts the user of a conflict and allows them to merge their local checklist changes with the server's changes side-by-side.
3. **Rich Media Handling and Caching:** I would improve the handling of photo uploads and signatures by adding aggressive local caching, better retry mechanisms for large files on spotty networks, and deeper integration with native background upload tasks.
4. **Real-Time Push Updates:** I would implement WebSockets (via Django Channels) to push live job updates or emergency dispatches directly to the technician's device, removing the need for manual pull-to-refresh or polling.
