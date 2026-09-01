# Serenity — Frontend (Flutter)

The mobile app is a Flutter project in `serenity/`.

## Stack

- **State management** — Riverpod (`flutter_riverpod`)
- **Networking** — Dio (with an auth interceptor + error mapping)
- **Local storage** — sqflite (session tokens + current user)
- **Navigation** — native `Navigator` (named routes; **no go_router**)
- **Theme** — black base + burnt-orange accent (Google Fonts via `google_fonts`)
- **Chat** — Socket.IO client (`socket_io_client`), audio recording (`record`),
  playback (`audioplayers`)
- **Images** — `cached_network_image`, `image_picker`

## Requirements

- Flutter 3.x (project generated with Flutter 3.41 / Dart 3.11)
- A running backend (see `docs/BACKEND.md`)

## Running

```bash
cd serenity
flutter pub get
flutter run
```

### Pointing at your backend

The base URL defaults to `http://10.0.2.2:8000` (the Android emulator's alias for the
host machine). Override it with `--dart-define`:

```bash
# Android emulator (default)
flutter run

# iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:8000

# Physical device — use your machine's LAN IP
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000 \
            --dart-define=SOCKET_URL=http://192.168.1.10:8000
```

> A physical device cannot reach `localhost`; use the machine's LAN IP and ensure the
> backend is listening on `0.0.0.0:8000` (Docker Compose binds it by default).

## Architecture (`lib/`)

The app follows a clean, layered structure:

```
lib/
├── main.dart                 # ProviderScope + runApp
├── core/                     # Framework-agnostic building blocks
│   ├── config/               # app_config.dart (base URL, constants)
│   ├── constants/
│   ├── theme/                # colors, ThemeData, ThemeExtension
│   ├── errors/               # AppException hierarchy + Dio error mapping
│   ├── network/              # DioClient
│   ├── storage/              # LocalDatabase (sqflite) + SessionStore
│   ├── router/               # native Navigator routes
│   ├── providers/            # repository wiring
│   ├── extensions/           # context + widget styling extensions
│   └── utils/                # url_utils, time_ago
├── data/                     # Data layer
│   ├── models/               # plain Dart models with fromJson
│   ├── datasources/remote/   # per-domain Dio clients
│   └── repositories/         # thin repository layer (auth persists session)
└── presentation/
    ├── app.dart              # MaterialApp + theme + routes
    ├── widgets/              # shared ArticleCard, PostCard, UserAvatar, etc.
    └── features/
        ├── auth/             # splash, landing, login, register, forgot
        ├── onboarding/       # interest selection
        ├── home/             # bottom-nav shell
        ├── feed/             # feed, read article, search
        ├── post/             # create post, saved
        ├── profile/          # my profile, top readers, visitor profile
        ├── chat/             # chat list, chat (audio), socket service
        └── notifications/
```

### Why this structure

- **`core/`** has no Flutter-`BuildContext`-dependent business logic where possible, so it
  is fast and easy to reason about.
- **`data/`** owns serialisation and I/O; `presentation/` never talks to Dio/sqflite
  directly.
- Repositories are provided via Riverpod providers and injected into screens through
  `ref.read`/`ref.watch`.

## Styling & performance extension

To keep UI code terse and avoid rebuild churn:

- `AppColors` / `AppSpacing` / `AppRadius` are **const** values.
- `AppThemeExtension` (a `ThemeExtension`) exposes theme tokens; access via
  `context.themeExt` (see `core/extensions/context_extensions.dart`).
- `widget_extensions.dart` provides small layout helpers (`.pad()`, `.center()`,
  `.onTap()`, …).
- Context helpers (`context.push(...)`, `context.showSnack(...)`) shorten navigation and
  feedback calls.

## Theming

- Base: black (`#0A0A0A` background, `#141414` surfaces).
- Accent: burnt orange `#E4572E` (derived from `assets/logo.png`).
- Fonts: Inter via `google_fonts` (falls back gracefully offline).

## Launcher icons

Launcher icons are generated from `assets/logo.png` with `flutter_launcher_icons`:

```bash
dart run flutter_launcher_icons
```

This writes the Android mipmaps and the iOS `AppIcon.appiconset` automatically.

## Notes / production hardening

- Tokens are stored in **sqflite** for simplicity; for production consider
  `flutter_secure_storage`.
- The audio message path requires the mic permission (handled at runtime by `record`).
- Authentication is **credential-only** (email + name + password).
