# Repository Deductions and Inferences

## Overview
This is a full-stack monorepo for a "black + burnt-orange themed mobile content & social reader" called **Serenity**. It aggregates news, articles, and jokes into a personalised feed with social features (profiles, top readers, chat with audio messages, posts, reshares, notifications).

## Two-Tier Architecture

### Mobile App (`serenity/`)
- **Framework**: Flutter 3.x, Dart 3.11
- **State Management**: Riverpod (`flutter_riverpod` ^2.6.1)
- **Networking**: Dio with auth interceptor + error mapping
- **Local Storage**: sqflite (session tokens + current user)
- **Navigation**: Native `Navigator` (named routes; no go_router)
- **Chat**: Socket.IO client (`socket_io_client` ^3.1.6), audio recording (`record`), playback (`audioplayers`)
- **Images**: `cached_network_image`, `image_picker`
- **Theme**: Black base (#0A0A0A) with burnt-orange accent (#E4572E), Google Fonts via `google_fonts`
- **Clean Architecture**: `core/` (framework-agnostic), `data/` (I/O/serialization), `presentation/` (UI)
- **Features**: auth, onboarding, home, feed, post, profile, chat, notifications

### Backend (`serenity_backend/`)
- **API Gateway** (`api-gateway`): Node TS + Express, port 8000. Responsibilities: routing, JWT verification, rate limiting, Swagger UI. Only public entry point.
- **Auth Service** (`auth-service`): Node TS + Express + Prisma + PostgreSQL, port 8001. Credential auth (email/password), JWT + refresh tokens (refresh tokens stored as SHA-256 hashes), password reset.
- **Chat Service** (`chat-service`): Node TS + Express + Prisma + Socket.IO, port 8002. Conversations, messages, audio messages, realtime events via Socket.IO.
- **Feed Service** (`feed-service`): Go + Gin + GORM, port 8004. Aggregates news/jokes, personalised feed, search, saved articles, interest catalog.
- **Post Service** (`post-service`): Go + Gin + GORM, port 8005. Posts (text/image), likes, reshares, saved posts, image upload.
- **User Service** (`user-service`): Go + Gin + GORM, port 8006. Profiles, top readers (activity ranking), follow, activity tracking.
- **Notification Service** (`notification-service`): Go + Gin + GORM, port 8007. In-app notifications.

- **Database**: 6 independent PostgreSQL instances (one per stateful service), ports 5432-5437 host-exposed. Each service owns its own DB for decoupling and independent scalability.

- **Auth & Trust Model**:
  1. `auth-service` issues short-lived access token + rotating refresh token
  2. Mobile app sends `Authorization: Bearer <accessToken>` on every request
  3. Gateway verifies token and injects `x-user-id`/`x-user-email`/`x-user-name` headers
  4. Downstream services read those headers; never re-verify JWTs (gateway is security boundary)
  5. Socket.IO traffic: chat service verifies JWT from socket handshake itself

- **Cross-Service Events**:
  - Activity/top readers: `feed-service` records `read`, `post-service` records `post`/`share` events by calling `POST /users/:id/activity` on `user-service` (fire-and-forget). `user-service` aggregates into activity score, exposes `GET /users/top-readers`.
  - Notifications: when a user is followed, `user-service` posts a notification to `notification-service`.

- **External Providers** (all optional; `MOCK_MODE=true` seeds sample content):
  - GNews API
  - Currents API
  - Joke API (jokeapi.dev)
  - Official Joke API

- **Docker Compose**: Single entry point orchestrates all services + 6 PostgreSQL databases. Gateway is the only port exposed (8000). Each service binds to its internal port; host ports mapped accordingly.

## Key Design Decisions

1. **Microservice decomposition by business capability** (not by technology) — Node for auth/chat (Prisma/Socket.IO), Go for feed/posts/users/notifications (GORM/Gin).
2. **Per-service PostgreSQL databases** — ensures strong isolation, independent scaling, but increases operational complexity (6 DBs to manage).
3. **API gateway as sole security boundary** — centralizes JWT verification, rate limiting, and header injection; downstream services trust forwarded headers.
4. **Fire-and-forget activity events** — no synchronous cross-service calls for activity scoring; eventual consistency via `user-service` aggregation.
5. **Mock mode for development** — `MOCK_MODE=true` allows the app to function without news API keys, using seeded sample content.
6. **Native Navigator (no go_router)** — simpler routing but less type-safe than router-based approaches.
7. **sqflite for token/user persistence** — noted as a production consideration to move to `flutter_secure_storage`.

## Data Flow Examples

- **Feed**: `app → GET /feed (gateway) → feed-service → reads user interests → returns articles → records "read" → user-service (activity)`
- **Chat (text)**: `app → Socket.IO /socket.io (gateway → chat-service) → JWT verify → join room → "conversation:send" → persist message → emit to participants`
- **Chat (audio)**: `app → POST /chat/conversations/:id/messages/audio (multipart) → store file → persist message with mediaUrl → playback via gateway-proxied GET`
- **Auth**: `app → POST /auth/register/login → auth-service → JWT tokens → store in sqflite → send Authorization header on subsequent requests`

## Risks and Observations

- **Operational overhead**: 6 separate PostgreSQL databases + 7 microservices increases deployment and monitoring complexity.
- **Single gateway bottleneck**: all external traffic funnels through the gateway; single point of failure if not replicated.
- **Refresh token storage**: currently in sqflite; less secure than `flutter_secure_storage` for production.
- **Socket.IO through gateway**: requires WebSocket passthrough configuration; ensure the gateway handles upgrade requests.
- **No type-safe routing** on the mobile side (native Navigator); feature additions may require careful route management.
- **Go version**: `go.mod` shows Go 1.24 — verify compatibility with the installed Go toolchain.