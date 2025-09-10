# MazdoorHub Flutter App (v1.1) — Maps + Offline + RTL + TTS + WhatsApp

Created: 2025-09-07

## New in this version
- **Map + List toggle** on Jobs screen (Mapbox tiles via `flutter_map`)
- **Offline-first**: jobs cached locally (SharedPreferences JSON; swappable with Isar/Drift)
- **Urdu-first UI**: RTL toggle from menu; larger typography for readability
- **Voice prompts** (TTS) on critical actions (load jobs, job created)
- **WhatsApp deep link** button from jobs screen (ops escalation / help)

## Configure
Pass API/WS + Mapbox token at run time:
```
flutter run   --dart-define=API_BASE=https://<api-id>.execute-api.ap-south-1.amazonaws.com/dev   --dart-define=WS_URL=wss://<ws-id>.execute-api.ap-south-1.amazonaws.com/dev
```
Then in the app, tap the **map icon** in the top bar to paste your **Mapbox token** (saved locally).

## Notes
- The backend `/jobs`, `/payments`, `/notifications`, `/trust` are already wired.
- Chat is an **echo MVP**; when backend routing is ready, swap the WS URL.
- For robust offline, migrate the cache service to **Isar/Drift**; the API remains the same.
