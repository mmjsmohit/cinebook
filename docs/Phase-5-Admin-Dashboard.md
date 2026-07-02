# Phase 5 — Admin Dashboard (React + Vite)

**Stack:** Vite + React + TypeScript, React Router, a data-fetching layer (TanStack Query recommended), a light chart lib (Recharts).
**Purpose:** A thin web control center over admin-scoped APIs — user management, catalog, theatre/screen config, reports, activity log, override scheduling.

**Tightly tied to:**
- **Consumes Phase 1 services** through `/admin/*` routes (same service layer as everything else — admin routes are thin wrappers with `requireRole('ADMIN')`).
- Shares Phase 1's auth (JWT) and error envelope. No new domain logic lives here.

Keep it deliberately simple — correctness and the **activity log** (accountability) are what's graded, not visual polish.

---

## 1. Admin API surface (add to Phase 1)

All gated by `requireRole('ADMIN')`; every mutating call writes an `AdminActivityLog` row.

```
# Users
GET   /admin/users
PATCH /admin/users/:id
POST  /admin/users/:id/disable
POST  /admin/users/:id/role          # { role }

# Catalog
POST  /admin/movies      PATCH /admin/movies/:id
POST  /admin/theatres    PATCH /admin/theatres/:id
POST  /admin/screens     PATCH /admin/screens/:id   # incl. seat layout + equipment

# Override scheduling (any screen; bypasses ownership)
POST  /admin/shows

# Reports & audit
GET   /admin/reports?range=daily|weekly|monthly
GET   /admin/activity-log?actorId=&from=&to=
```

The show-creation endpoint reuses Phase 1's `showService` (§7 there) but skips the manager-ownership check — that's the "override powers" requirement.

---

## 2. Pages

| Route | Purpose | API |
|---|---|---|
| `/users` | list, edit, disable, assign role | `/admin/users*` |
| `/movies` | add/update movies (title, description, runtime, cast, poster, trailer) | `/admin/movies*` |
| `/theatres` | add chains + locations | `/admin/theatres*` |
| `/screens` | configure screens: type, format, equipment, seat layout | `/admin/screens*` |
| `/shows` | override-schedule on any screen | `/admin/shows` |
| `/reports` | daily/weekly/monthly bookings + revenue, with charts | `/admin/reports` |
| `/activity` | admin action audit trail | `/admin/activity-log` |

---

## 3. Reports

Aggregate **server-side** (don't ship rows to the client): booking counts and revenue bucketed by day/week/month. Client renders totals + a Recharts bar/line. Keep the query in `showService`/`bookingService` so it's testable.

---

## 4. Activity log (accountability)

Every admin mutation → `AdminActivityLog { actorId, action, entity, metadata, createdAt }` (Phase 1 schema). The `/activity` page is a filterable table. This directly satisfies the doc's "Activity Log — record of all admin actions for accountability."

---

## 5. Auth & routing

- Reuse the OTP → JWT flow; admin logs in the same way, role must be `ADMIN`.
- Store the access token in memory + refresh via `/auth/refresh`; guard routes with a `<RequireAdmin>` wrapper that redirects on missing/expired session.
- Same `{ error: { code, message } }` envelope → surface inline.

---

## 6. Definition of done

- [ ] Admin can view/edit/disable users and reassign roles.
- [ ] Catalog + theatre/screen config CRUD works (including seat layouts).
- [ ] Admin can override-schedule a show on any screen.
- [ ] Reports show correct daily/weekly/monthly bookings + revenue.
- [ ] Every admin action appears in the activity log with actor + timestamp.

---

## 7. Reference documentation

- Vite — https://vite.dev/
- React — https://react.dev/
- React Router — https://reactrouter.com/
- TanStack Query (data fetching/caching) — https://tanstack.com/query/latest
- Recharts (charts) — https://recharts.org/
- Phase 1 services + auth + error envelope — `Phase-1-CRUD-Backend.md`
