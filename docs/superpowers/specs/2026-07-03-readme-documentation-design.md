# Design Specification: CineBook Monorepo README Documentation

This specification details the structural design, content requirements, and Mermaid diagrams for the README files to be created across the CineBook codebase.

## 1. Documentation Architecture

We will adopt a multi-tier documentation system (Approach 1: Top-Down Multi-App Architecture) consisting of a high-level system-wide gateway at the root and deep, self-contained, technical READMEs within each workspace folder.

```
/ (Project Root)
├── README.md (High-Level Topology, System Overview, Getting Started)
├── cinebook-server/
│   └── README.md (Agent details, Custom Orchestration, Concurrency, Rate Limiting, Metrics)
├── cinebook-admin/
│   └── README.md (React Dashboard, Reports, Role management, Logs)
├── cinebook_core/
│   └── README.md (Shared Dart client, DTOs, Auth Token storage)
├── cinebook_user_app/
│   └── README.md (Customer client, Chat BLoC, SSE parsing, Live seat map polling)
└── cinebook_hall_app/
    └── README.md (Hall Manager client, Scheduling views, Rule violation feedback)
```

---

## 2. Document Specs & Outline

### 2.1. Root `README.md`
* **Core Goal**: Welcome developers, explain the overall system topology, list workspace modules, and detail high-level environment setup.
* **Key Components**:
  * **System Topology Diagram**: A Mermaid chart showcasing how all apps connect (User/Hall apps -> shared Core client -> Server, Admin web -> Server, Server -> Postgres + Redis).
  * **Architectural Principles**:
    * **Dual-Path Strategy**: Separates the real-time AI Chat stream (SSE over HTTP) from the concurrent transactional Seat Map (HTTP Polling + Redis locking).
    * **No Agent Framework**: The AI agent is a custom Node loop on top of `streamText`, avoiding LangChain/LlamaIndex.
  * **Workspace Inventory**: Directory table with names, languages, frameworks, and roles.
  * **Prerequisites & Global Installation**: Quick instructions to clone, run Docker-compose (Postgres + Redis), migrate schemas, seed databases, and run all apps concurrently.

### 2.2. Backend Server (`cinebook-server/README.md`)
* **Core Goal**: Exhaustively detail the TypeScript Express backend, Prisma/PostgreSQL schemas, Redis seat-holding, custom AI agent orchestrator, and payment circuit breakers.
* **Key Components**:
  * **Architecture Diagram**: Mermaid diagram of the backend layers (HTTP Routers -> Express Controllers -> Domain Services -> Prisma/Redis Infra, and HTTP Controllers -> custom Orchestrator -> Booking Agent).
  * **AI Agent Subsystem (Custom Loop)**:
    * Custom `streamText` loop with context compaction (`prepareStep`) and conversation persistence.
    * Tool Registry: The 26 server-side tools grouped by domain (Movie, Booking, Profile/Support).
    * Sub-agent Delegation: The booking assistant hand-off mechanism and outputs.
    * AG-UI Event Stream (SSE): Mapping AI SDK parts to SSE client events.
  * **Concurrency & Holds Design**:
    * Seat hold lifecycle: Redis keys `seat:{showId}:{seatId}` using the `SET NX PX` command (5-min TTL).
    * Safe release: Lua compare-and-delete script.
    * Confirmations: Postgres transaction + `SELECT ... FOR UPDATE` + DB unique constraints as the final safety guard.
  * **Business Scheduling Rules**: Rules engine preventing overlapping shows, maintaining 30-min gaps, capping show creations at 30 days ahead, checking manager screen ownership, and blocking edits if tickets are booked.
  * **Resiliency & Cross-cutting**: Sliding window rate limits, Redis payment circuit breaker, and structured logging with correlation IDs.

### 2.3. User App (`cinebook_user_app/README.md`)
* **Core Goal**: Document the Flutter client for customers, detailing chat event consumption and live seat map polling.
* **Key Components**:
  * **App Architecture Diagram**: Mermaid diagram detailing UI Screens -> Chat & Seat map BLoCs -> `cinebook_core` API client.
  * **AI Chat Event Consumption Flow**: Data flow detailing SSE event streaming -> `ChatBloc` -> Event translator -> Rich widget rendering (e.g. native seat map in-chat).
  * **Seat map synchronization**: Description of the periodic polling loop (every 2-3 seconds) and 5-minute countdown.
  * **Local Environment Setup**: Flutter environment setup, running commands.

### 2.4. Hall App (`cinebook_hall_app/README.md`)
* **Core Goal**: Document the scheduling client for managers, detailing how business scheduling rules are surfaced.
* **Key Components**:
  * **App Architecture Diagram**: Mermaid diagram detailing UI screens -> Scheduler BLoC -> `cinebook_core` client.
  * **Data Flow Diagram**: Creation/edit of show times -> API Request -> Server validation engine -> Specific error rendering.
  * **Local Environment Setup**: Commands for building and running.

### 2.5. Admin App (`cinebook-admin/README.md`)
* **Core Goal**: Document the React Vite admin dashboard.
* **Key Components**:
  * **Admin Architecture & Flow**: Catalog CRUD, user role management, system overrides, activity logging, and daily/weekly/monthly revenue reporting (rendered via lightweight chart components).
  * **Development & Build Commands**: Package setup, Vite commands.

### 2.6. Core Package (`cinebook_core/README.md`)
* **Core Goal**: Document the shared Dart plumbing package.
* **Key Components**:
  * **Plumbing Layer**: Mappings of DTOs, API Client wrapper (Dio) with interceptors for JWT injection/refresh on 401, and secure token storage manager (`flutter_secure_storage`).
  * **Setup & Usage**: Linking via `pubspec.yaml` path dependencies.

---

## 3. Review Gate & Next Steps

This specification provides the blueprints. Upon user approval, we will create/update the README files in place.
No placeholders or incomplete sections will be left. All files will contain correct relative paths and markdown formatting.
