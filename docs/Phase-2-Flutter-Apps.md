# Phase 2 — Flutter Apps (non-AI)

**Stack:** Flutter, Bloc (state management), Material 3, `dio` (HTTP), `flutter_secure_storage` (tokens).
**Purpose:** Two separate Flutter apps — the customer app and the hall-manager app — implementing every non-AI screen against the Phase 1 REST contract.

**Tightly tied to:**
- **Consumes Phase 1** — every screen calls an endpoint defined in `Phase-1-CRUD-Backend.md`. Endpoint names here must match exactly.
- **User app is extended in Phase 4** — the chatbot tab is added there; build the app so a new tab drops in cleanly.
- Hall app is standalone (no AI).

---

## 1. Two-app structure

```
cinebook-user-app/    # customer + (Phase 4) chatbot
cinebook-hall-app/    # hall manager only
```

**Optional shared package** `cinebook_core` (pulled into both via `path:` dependency): API client, DTO models, token storage, auth Bloc. This is shared *plumbing*, not shared UI — it removes duplication without the role-conditional UI you wanted to avoid. If you skip it, copy the `core/` folder into each app.

---

## 2. Shared foundation (both apps)

- **Bloc** per feature: `AuthBloc`, plus feature Blocs below. Events in, states out, no logic in widgets.
- **`dio` client** with two interceptors:
  1. Attach `Authorization: Bearer <access>`.
  2. On `401` → call `/auth/refresh` once, retry the original request; on refresh failure → emit `AuthUnauthenticated`.
- **`flutter_secure_storage`** holds `accessToken` + `refreshToken` → satisfies "stay logged in across sessions." Load on app start into `AuthBloc`.
- **Error envelope:** parse Phase 1's `{ error: { code, message } }` and surface `message` in a snackbar/inline.

---

## 3. User app — screens & flows

| Screen | Endpoint(s) | Notes |
|---|---|---|
| OTP login | `/auth/request-otp`, `/auth/verify-otp` | phone → code → tokens |
| Movie list | `GET /movies?...filters` | filter sheet: genre, chain, screen type, format, language, age rating, date |
| Movie detail | `GET /movies/:id`, `/reviews`, `/similar` | cast, poster, trailer link, reviews, "similar" rail |
| Showtimes | `GET /shows?movieId=&date=&city=&screenType=&format=` | pick a show → `showId` |
| **Seat map** | `GET /shows/:id/seats` (poll), `POST /shows/:id/holds` | see §5 |
| Payment | `POST /bookings`, `POST /payments` | test card entry; 1–3 s processing UI |
| Confirmation | `GET /bookings/:id` | booking ID + summary |
| History | `GET /me/bookings` | past bookings; cancel → `POST /bookings/:id/cancel` |

Feature Blocs: `MovieListBloc`, `MovieDetailBloc`, `ShowtimesBloc`, `SeatMapBloc`, `BookingBloc`, `PaymentBloc`, `HistoryBloc`.

---

## 4. Hall app — screens & flows

| Screen | Endpoint(s) | Notes |
|---|---|---|
| OTP login | `/auth/*` | role must be `HALL_MANAGER` |
| My screens | `GET /me/screens` | assigned screens only |
| Show calendar | `GET /screens/:id/shows?from=&to=` | per-screen agenda |
| Create show | `POST /screens/:id/shows` | movie + start + basePrice + language + format |
| Edit / delete | `PATCH /shows/:id`, `DELETE /shows/:id` | disabled if the show has bookings |

**Render the server's specific rule errors verbatim** (overlap / 30-min gap / 30-day window / booked-lock / ownership). Client-side hints are fine, but the server is source of truth — never let the UI approve something the server would reject.

Blocs: `ScreensBloc`, `ShowScheduleBloc`, `ShowEditorBloc`.

---

## 5. Seat map polling (the tricky UI)

`SeatMapBloc` drives it:
- On enter: fetch `GET /shows/:id/seats`, render a grid colour-coded by state (`free`/`held`/`booked`) and by category (front/standard/premium/recliner), with a legend.
- **Poll** every 2–3 s via a `Timer` inside the Bloc; diff the response and update only changed seats (avoid full rebuilds/flicker).
- On seat tap → `POST /shows/:id/holds { seatIds }`. On `409`, show which seats were taken and refresh.
- Start a **5-minute countdown** from `expiresAt`; at zero, auto-release locally and re-poll. Carry the `holdToken` into `POST /bookings`.
- Cancel the timer in `close()` to avoid leaks.

This is the only place polling lives — it's deliberately separate from the Phase 4 chat stream.

---

## 6. Definition of done

- [ ] Both apps log in, persist sessions across restarts, and refresh tokens on `401`.
- [ ] Customer completes a booking end-to-end with **live seat updates** and a working hold countdown.
- [ ] `409` on a taken seat is handled gracefully (no crash, clear message, refresh).
- [ ] Hall manager schedules within the rules and sees the exact server error when breaking one.
- [ ] User app has an empty slot/tab ready for the Phase 4 chatbot.

---

## 7. Reference documentation

- Flutter docs — https://docs.flutter.dev/
- Bloc library (patterns, `flutter_bloc`) — https://bloclibrary.dev/
- Material 3 in Flutter — https://docs.flutter.dev/ui/widgets/material
- `dio` (HTTP client, interceptors) — https://pub.dev/packages/dio
- `flutter_secure_storage` — https://pub.dev/packages/flutter_secure_storage
- Phase 1 REST contract — `Phase-1-CRUD-Backend.md` (this repo)
