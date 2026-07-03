# CineBook Admin Dashboard (`cinebook-admin`)

This is the system administrator dashboard. It is implemented as a lightweight React application built with TypeScript, bundler tools from Vite, and styled with vanilla CSS.

## 1. Features

- **Catalog Management**: View and modify the primary system entities (Movies, Genres, Theatres, Screens).
- **User Role Administration**: Search user records, edit profile roles (Customer, Hall Manager, Admin), or disable/enable accounts.
- **Auditing Logs**: View chronological entries in the `AdminActivityLog` mapping critical actions back to actor IDs.
- **Revenue Analytics**: Visualizes daily, weekly, and monthly ticket sales and bookings count.
- **Scheduling Override**: Allows administrators to bypass screen manager checks and force scheduling overrides if necessary.

---

## 2. Component Structure

The app maintains a modular file-system splitting views by administrative domains:

```
src/
├── components/          # Reusable tables, forms, and charts
│   ├── RevenueChart.tsx # Lightweight charts displaying aggregates
│   └── Sidebar.tsx
├── pages/               # High-level route controllers
│   ├── Catalog.tsx      # Movie and theater CRUD interfaces
│   ├── Users.tsx        # Account enabling and role management
│   ├── AuditLogs.tsx    # Chronological history viewer
│   └── Dashboard.tsx    # Revenue visualizer
├── services/            # Client api wrappers
│   └── api.ts
└── App.tsx              # React router definitions
```

---

## 3. Development Setup

Install dependencies and start the Vite server:
```bash
# Install packages
npm install

# Run in development mode (with HMR)
npm run dev

# Build production assets
npm run build
```
