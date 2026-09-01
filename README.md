# Serenity

A black + burnt-orange themed mobile content & social reader. Serenity aggregates news, content and jokes into a personalised feed, and adds a social layer: profiles, top readers, chat (with audio messages), posts, reshares and notifications.

This is a full-stack monorepo:

- **`serenity/`** — Flutter mobile app (Riverpod, Dio, sqflite, native Navigator).
- **`serenity_backend/`** — Microservice backend (Node TS + Prisma and Go + GORM, all PostgreSQL), with an API gateway and Docker Compose.
- **`docs/`** — Architecture, backend, frontend and API documentation.

## Features

- **Authentication** — email + name + password auth, password reset,
  splash, landing and interest-based onboarding.
- **Home, feed & search** — personalised feed from GNews / MediaStack / Currents /
  Joke APIs (with mock fallback), full article reading, save, reshare, moderation
  filters and search.
- **Users** — personal & public profiles, top-readers discovery ranked by activity,
  follow, chat with audio messages, notifications, and text/image posts.
- **Theme** — black base with a burnt-orange accent (matching the logo).

## Quick links

- [Architecture overview](docs/ARCHITECTURE.md)
- [Backend guide](docs/BACKEND.md)
- [Frontend guide](docs/FRONTEND.md)
- [API endpoints](docs/API.md)

## Getting started

### Backend (Docker)

```bash
cd serenity_backend
cp .env.example .env   # add your news API keys (or keep MOCK_MODE=true)
docker compose up --build
```

- API gateway: http://localhost:8000
- Swagger docs: http://localhost:8000/docs

### Mobile app

```bash
cd serenity
flutter pub get
flutter run
```

See `docs/FRONTEND.md` for full setup (launcher icons, fonts, emulator/device).
