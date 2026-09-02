# Serenity — Backend

The backend is a set of containerised microservices orchestrated with Docker Compose.

## Requirements

- Docker + Docker Compose (any recent version)
- (optional, for local development without Docker) Node 22+ and Go 1.24+

## Quick start

```bash
cd serenity_backend
cp .env.example .env      # optional — defaults work out of the box
docker compose up --build
```

When all services are healthy:

- API gateway:  http://localhost:8000
- Swagger UI:   http://localhost:8000/docs
- Health check: http://localhost:8000/health

> On first boot the Postgres containers run their health checks before services start.
> Prisma (auth/chat) and GORM (Go services) auto-create their schemas on startup.

## Services & ports

| Service | Port (host) | Stack |
| --- | --- | --- |
| api-gateway | 8000 | Node TS · Express |
| auth-service | 8001 | Node TS · Express · Prisma |
| chat-service | 8002 | Node TS · Express · Prisma · Socket.IO |
| feed-service | 8004 | Go · Gin · GORM |
| post-service | 8005 | Go · Gin · GORM |
| user-service | 8006 | Go · Gin · GORM |
| notification-service | 8007 | Go · Gin · GORM |

PostgreSQL instances (one per stateful service) are exposed on host ports 5432–5437 for
debugging only; inside the network each service talks to its own `*-db` host.

## Environment variables

All variables are defined in `.env.example`. The most important:

| Variable | Default | Purpose |
| --- | --- | --- |
| `JWT_SECRET` | `change-me` | Signing key shared by gateway + auth + chat |
| `JWT_ACCESS_EXPIRES` | `15m` | Access token lifetime |
| `JWT_REFRESH_EXPIRES` | `30d` | Refresh token lifetime |
| `APP_BASE_URL` | `http://localhost:8000` | Public base URL of the gateway |
| `MOCK_MODE` | `true` | Seed sample feed content when no news API keys are set |
| `GNEWS_API_KEY` | (empty) | GNews API key |
| `CURRENTS_API_KEY` | (empty) | Currents API key |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | `serenity` / `serenity` | Shared DB credentials |

The joke providers (`JOKE_API_URL`, `OFFICIAL_JOKE_API_URL`) are free and need no key.

## Testing locally

### Health checks

```bash
curl http://localhost:8000/health
curl http://localhost:8000/health            # gateway
curl http://localhost:8001/health            # auth (direct)
```

### Auth flow

```bash
# register -> signs you straight in and returns tokens (no verification step)
curl -X POST http://localhost:8000/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"ada","password":"password123","name":"Ada","gender":"female"}'

# login
curl -X POST http://localhost:8000/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"ada","password":"password123"}'
```

Use the returned `accessToken` for authenticated requests:

```bash
curl http://localhost:8000/feed -H 'Authorization: Bearer <accessToken>'
```

### Password changes

There is no email in the system, so there is **no password reset flow** — a
forgotten password cannot be recovered. A signed-in user can change theirs:

```bash
curl -X POST http://localhost:8000/auth/change-password \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{"currentPassword":"password123","newPassword":"newpassword123"}'
```

## Local development without Docker

Each service can be run directly. Example for the auth service:

```bash
cd serenity_backend/auth-service
npm install
npx prisma generate
DATABASE_URL='postgresql://serenity:serenity@localhost:5438/auth?schema=public' npm run dev
```

Example for the feed service:

```bash
cd serenity_backend/feed-service
DATABASE_URL='postgresql://serenity:serenity@localhost:5434/feed?sslmode=disable' go run ./cmd
```

(You still need Postgres running — `docker compose up auth-db feed-db` etc.)

## Error handling convention

All services return errors as JSON with a stable shape:

```json
{ "error": "Unauthorized", "message": "Invalid or expired access token" }
```

- Node services throw typed `AppError` subclasses caught by a central error handler.
- Go services use a `respondError` helper and `gin`'s recovery middleware.
- The gateway maps upstream failures to `502 Bad Gateway`.

## Clean architecture within each service

```
service/
├── cmd/                 # Go entrypoint (or src/ for Node)
├── internal/            # Go packages (config, database, model, repository, handler)
└── prisma/              # Node services only — Prisma schema
```

- **model** — domain entities / GORM models.
- **repository** — data access, isolated from transport.
- **handler/controller** — HTTP transport + input validation.
- **service** — business logic (Node auth/chat).
- **config / database** — environment and persistence wiring.
