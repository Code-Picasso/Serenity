# Serenity Backend

Microservice backend for Serenity, orchestrated with Docker Compose.

## Services

| Service | Stack | Port |
| --- | --- | --- |
| api-gateway | Node TS · Express | 8000 |
| auth-service | Node TS · Express · Prisma | 8001 |
| chat-service | Node TS · Express · Prisma · Socket.IO | 8002 |
| feed-service | Go · Gin · GORM | 8004 |
| post-service | Go · Gin · GORM | 8005 |
| user-service | Go · Gin · GORM | 8006 |
| notification-service | Go · Gin · GORM | 8007 |

Each stateful service has its own PostgreSQL database.

## Run

```bash
cp .env.example .env   # optional
docker compose up --build
```

- Gateway: http://localhost:8000
- Swagger: http://localhost:8000/docs

## Configure news providers

Add API keys to `.env` (or leave empty and keep `MOCK_MODE=true` for seeded sample
content):

```bash
GNEWS_API_KEY=
CURRENTS_API_KEY=
```

See `../docs/BACKEND.md` for full details and `../docs/API.md` for the endpoint
reference.
