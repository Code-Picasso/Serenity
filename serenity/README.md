# Serenity (Flutter app)

The Serenity mobile client — a black + burnt-orange content & social reader.

## Stack

- Riverpod (state), Dio (networking), sqflite (local storage)
- Native Navigator (no go_router)
- Google Fonts, Socket.IO chat, audio messages

## Run

```bash
flutter pub get
flutter run
```

Point at your backend (defaults to the Android emulator host alias):

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000 \
            --dart-define=SOCKET_URL=http://localhost:8000
```

Regenerate launcher icons from `assets/logo.png`:

```bash
dart run flutter_launcher_icons
```

Full architecture and setup details: `../docs/FRONTEND.md`.

