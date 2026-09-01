# Serenity — Architecture

Serenity is a content + social reader: it aggregates news, articles and jokes into a
personalised feed and layers a social experience (profiles, top readers, chat with audio
messages, posts, reshares and notifications) on top.

The project is a monorepo with two top-level components:

```
Serenity/
├── serenity/           # Flutter mobile app (Core / Data / Presentation)
├── serenity_backend/   # Microservices + Docker Compose
└── docs/               # Architecture, backend, frontend and API docs
```

## High-level design

```
┌──────────────┐         ┌──────────────────────────────────────────────────────────────┐
│  Flutter app │         │                     serenity_backend                        │
│  (Riverpod,  │  HTTPS  │  ┌─────────────┐                                            │
│   Dio,       │ ──────► │  │ api-gateway │  (Node TS · Express)                        │
│   sqflite)   │         │  │  :8000      │  JWT auth · rate limit · Swagger (/docs)   │
└──────────────┘         │  └──────┬──────┘                                            │
                         │         │ proxies                                            │
                         │  ┌───────┴───────┬───────────┬────────────┬───────────┐     │
                         │  ▼               ▼           ▼            ▼           ▼     │
                         │ auth-service   chat-service feed-service post-service ...   │
                         │ (Node/Prisma)  (Node/Prisma) (Go/GORM)   (Go/GORM)           │
                         │  :8001          :8002        :8004        :8005              │
                         │     │              │            │            │               │
                         │  auth-db       chat-db     feed-db      post-db             │
                         │  (Postgres)    (Postgres)  (Postgres)   (Postgres)          │
                         └──────────────────────────────────────────────────────────────┘
```

### Why this shape

- **Mobile app** follows clean architecture (`core/`, `data/`, `presentation/`) with
  Riverpod for state, Dio for networking and sqflite for local persistence. Navigation
  uses Flutter's **native Navigator** (no go_router).
- **Backend** is split by business capability, as requested:
  - **Node TS (Express) + Prisma + PostgreSQL** for **auth** and **chat**.
  - **Go (Gin) + GORM + PostgreSQL** for **feed**, **posts/sharing**, **users** and
    **notifications**.
- A single **API gateway** is the only publicly exposed entry point. It verifies JWTs,
  applies rate limiting, serves the Swagger UI and proxies to the right service.

## Service responsibilities

| Service | Stack | Port | DB | Responsibility |
| --- | --- | --- | --- | --- |
| `api-gateway` | Node TS · Express | 8000 | — | Routing, JWT verification, rate limiting, `/docs` Swagger UI |
| `auth-service` | Node TS · Express · Prisma | 8001 | `auth-db` | Credential auth (email/password), JWT + refresh tokens, password reset |
| `chat-service` | Node TS · Express · Prisma · Socket.IO | 8002 | `chat-db` | Conversations, messages, audio messages, realtime events |
| `feed-service` | Go · Gin · GORM | 8004 | `feed-db` | Aggregates news/jokes, grouped interest catalog (news/sports/humor), personalised feed, search, saved articles |
| `post-service` | Go · Gin · GORM | 8005 | `post-db` | Posts (text/image), likes, reshares, saved posts, image upload |
| `user-service` | Go · Gin · GORM | 8006 | `user-db` | Profiles, top readers (activity ranking), follow, activity tracking |
| `notification-service` | Go · Gin · GORM | 8007 | `notification-db` | In-app notifications |

Each stateful service owns its own PostgreSQL database (6 total), keeping services
decoupled and independently scalable.

## Auth & trust model

1. `auth-service` issues a short-lived **access token** and a rotating **refresh token**
   (refresh tokens are stored as SHA-256 hashes).
2. The mobile app sends `Authorization: Bearer <accessToken>` on every request.
3. The **gateway** verifies the token and injects trusted headers
   (`x-user-id`, `x-user-email`, `x-user-name`) before proxying.
4. Downstream services read those headers and never need to re-verify JWTs
   (the gateway is the security boundary). Socket.IO traffic is the exception — the
   chat service verifies the JWT from the socket handshake itself.

## Cross-service events

- **Activity / top readers** — `feed-service` records a `read` and `post-service` records
  `read`/`post`/`share` events by calling `POST /users/:id/activity` on `user-service`
  (fire-and-forget). `user-service` aggregates these into an activity score and exposes
  `GET /users/top-readers` (ranked by score).
- **Notifications** — when a user is followed, `user-service` posts a notification to
  `notification-service`.

## Data flow examples

### Feed
```
app → GET /feed (gateway) → feed-service
                              ├─ reads user interests (feed-db)
                              ├─ returns articles ordered by published_at
                              └─ records "read" → user-service (when an article is opened)
```

### Chat (text)
```
app → Socket.IO /socket.io (gateway → chat-service)
chat-service verifies JWT, joins room user:<id>
"conversation:send" → persists message (chat-db) → emits to all participants' rooms
```

### Chat (audio)
```
app → POST /chat/conversations/:id/messages/audio (multipart)
chat-service stores the file in uploads/ and persists a message with mediaUrl
app → GET /chat/uploads/<file> (proxied through the gateway) to play it back
```

## External providers

`feed-service` ingests from (all optional — `MOCK_MODE=true` seeds sample content so the
app works with no API keys):

- GNews API
- Currents API
- Joke API (jokeapi.dev)
- Official Joke API

See `docs/BACKEND.md` for key configuration and `docs/API.md` for the endpoint reference.
