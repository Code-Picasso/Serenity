# Serenity — API Reference

All routes are served through the **gateway** at `http://localhost:8000`.
Interactive docs (Swagger UI) are available at `http://localhost:8000/docs`.

## Conventions

- JSON in/out. Errors use `{ "error": "<type>", "message": "<detail>" }`.
- Protected routes require `Authorization: Bearer <accessToken>`.
- The gateway verifies the JWT and forwards `x-user-id`/`x-user-email`/`x-user-name`
  to the service.

## Auth (`/auth`)

| Method | Path | Auth | Description |
| --- | --- | --- | --- |
| POST | `/auth/register` | — | Create account (`email`, `password`, `name`) |
| POST | `/auth/verify-email` | — | Verify account with emailed code (`code`) |
| POST | `/auth/resend-verification` | — | Resend verification code (`email`) |
| POST | `/auth/login` | — | Login with credentials |
| POST | `/auth/refresh` | — | Exchange refresh token for a new pair |
| POST | `/auth/logout` | ✓ | Revoke refresh token |
| GET | `/auth/me` | ✓ | Current user |
| POST | `/auth/forgot-password` | — | Request password reset |
| POST | `/auth/reset-password` | — | Reset with token + new password |
| POST | `/auth/change-password` | ✓ | Change password |

### Example — register response

```json
{ "message": "Check your email to verify your account.", "devVerificationToken": "123456" }
```

`devVerificationToken` is only returned when `NODE_ENV` is not `production` (so the
flow can be completed locally without SMTP). In production the code is emailed.

### Example — verify-email / login response

```json
{
  "user": { "id": "uuid", "email": "a@b.com", "name": "Ada", "avatarUrl": null, "provider": "credentials" },
  "accessToken": "<jwt>",
  "refreshToken": "<jwt>"
}
```

## Feed (`/feed`)

| Method | Path | Auth | Description |
| --- | --- | --- | --- |
| GET | `/feed` | ✓ | Personalised feed (`?page=`, `?limit=`, `?topic=`) |
| GET | `/feed/articles/:id` | ✓ | Single article |
| POST | `/feed/articles/:id/read` | ✓ | Record a read (activity) |
| POST | `/feed/articles/:id/save` | ✓ | Save an article |
| DELETE | `/feed/articles/:id/save` | ✓ | Unsave an article |
| GET | `/feed/saved` | ✓ | List saved articles |
| GET | `/feed/search` | ✓ | Search (`?q=`) |
| GET | `/feed/topics` | ✓ | Interest catalog — grouped sections (News, Sports, Entertainment, Social, Humor) + flat list |
| GET | `/feed/interests` | ✓ | Current user's interests |
| PUT | `/feed/interests` | ✓ | Replace interests (`{ "topics": [...] }`) |

## Posts (`/posts`)

| Method | Path | Auth | Description |
| --- | --- | --- | --- |
| GET | `/posts` | ✓ | List posts |
| POST | `/posts` | ✓ | Create post (`{ "text": "...", "imageUrl": "..." }`) |
| POST | `/posts/upload` | ✓ | Upload an image (multipart `image`) → `imageUrl` |
| GET | `/posts/:id` | ✓ | Single post |
| DELETE | `/posts/:id` | ✓ | Delete own post |
| POST | `/posts/:id/like` | ✓ | Toggle like |
| POST | `/posts/:id/reshare` | ✓ | Reshare a post |
| POST | `/posts/:id/save` | ✓ | Save a post |
| DELETE | `/posts/:id/save` | ✓ | Unsave a post |
| GET | `/posts/saved` | ✓ | List saved posts |
| GET | `/posts/reshared` | ✓ | List reshared posts |
| GET | `/posts/users/:userId/posts` | ✓ | Posts by a user |

## Users (`/users`)

| Method | Path | Auth | Description |
| --- | --- | --- | --- |
| GET | `/users/me` | ✓ | My profile (auto-provisioned) |
| PUT | `/users/me` | ✓ | Update profile |
| GET | `/users/top-readers` | ✓ | Top readers by activity (`?limit=`) |
| GET | `/users/:id` | ✓ | Public/visitor profile (`{ profile, isFollowing }`) |
| POST | `/users/:id/follow` | ✓ | Follow a user |
| DELETE | `/users/:id/follow` | ✓ | Unfollow a user |
| GET | `/users/:id/followers` | ✓ | List followers |
| GET | `/users/:id/following` | ✓ | List following |
| POST | `/users/:id/activity` | internal | Record activity (`{ "type": "read\|share\|post\|chat" }`) |

## Chat (`/chat`)

| Method | Path | Auth | Description |
| --- | --- | --- | --- |
| GET | `/chat/conversations` | ✓ | List my conversations |
| POST | `/chat/conversations` | ✓ | Create/open a direct conversation (`{ "userId": ... }`) |
| GET | `/chat/conversations/:id` | ✓ | Conversation detail |
| GET | `/chat/conversations/:id/messages` | ✓ | Messages (`?page=`, `?limit=`) |
| POST | `/chat/conversations/:id/messages` | ✓ | Send text (`{ "type": "text", "content": "..." }`) |
| POST | `/chat/conversations/:id/messages/audio` | ✓ | Send audio (multipart `audio`) |
| POST | `/chat/conversations/:id/read` | ✓ | Mark conversation read |

### Realtime (Socket.IO)

Connect to `ws://localhost:8000/socket.io` with auth `{ token: "<accessToken>" }`.

Client → server:

- `conversation:join` `{ conversationId }`
- `conversation:send` `{ conversationId, content, type }` (text)
- `conversation:typing` `{ conversationId, isTyping }`
- `conversation:read` `{ conversationId }`

Server → client:

- `conversation:message` — a new message object
- `conversation:typing` — a peer is typing
- `conversation:read` — a peer read the conversation

## Notifications (`/notifications`)

| Method | Path | Auth | Description |
| --- | --- | --- | --- |
| GET | `/notifications` | ✓ | List notifications |
| GET | `/notifications/unread-count` | ✓ | Unread count |
| POST | `/notifications` | internal | Create a notification |
| PUT | `/notifications/:id/read` | ✓ | Mark one read |
| PUT | `/notifications/read-all` | ✓ | Mark all read |
| DELETE | `/notifications/:id` | ✓ | Delete a notification |

## Health

| Method | Path | Auth | Description |
| --- | --- | --- | --- |
| GET | `/health` | — | Gateway health |
| GET | `/:service/health` | — | Direct service health (bypassing gateway) |
