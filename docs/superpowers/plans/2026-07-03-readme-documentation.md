# CineBook README Documentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a high-quality root README and highly detailed application-specific READMEs across the CineBook monorepo, complete with Mermaid topology, data flow, and architecture diagrams.

**Architecture:** We will implement Approach 1 (Top-Down Multi-App Architecture). The project root README acts as a high-level gateway, and each sub-app (`cinebook-server`, `cinebook_user_app`, `cinebook_hall_app`, `cinebook_core`, `cinebook-admin`) contains a detailed, self-contained technical README describing its architecture, data flows, and setup commands.

**Tech Stack:** Markdown, Mermaid.js.

## Global Constraints
- Do not add placeholders, TODOs, or TBDs in the files.
- Ensure all relative links to files and code are correct and valid.
- Maintain consistency in diagram definitions and terms.

---

### Task 1: Root README Documentation

**Files:**
- Create: `README.md`

**Interfaces:**
- Produces: Visual mapping and global setup steps for the entire CineBook system.

- [ ] **Step 1: Write root README file content**

Write the following contents to `/Users/mohittiwari/Dev/Cinebook/README.md`:

```markdown
# CineBook — AI-Powered Movie Booking Platform

CineBook is an immersive, AI-powered movie booking platform. It provides friction-free movie ticket reservation via two primary paths: a classic intuitive mobile UI flow and a highly capable natural language chatbot agent.

## 1. System Topology

The CineBook platform is structured as a monorepo containing a Node.js Express backend, a React Vite admin dashboard, a shared Dart client package, and two separate Flutter applications for customers and hall managers respectively.

```mermaid
graph TD
  subgraph Client Tier
    Admin[Admin Dashboard <br> React + Vite]
    UserApp[User App <br> Flutter]
    HallApp[Hall App <br> Flutter]
  end

  subgraph Shared Code
    Core[cinebook_core <br> Shared Dart Plumbing]
  end

  subgraph Server Tier
    Server[cinebook-server <br> Node.js, Express, TS]
    Agent[Custom AI Agent <br> Vercel AI SDK streamText]
  end

  subgraph Data Tier
    Postgres[(PostgreSQL <br> Active Data)]
    Redis[(Redis <br> Holds, Limiters, Circuit Breaker)]
  end

  UserApp -.-> Core
  HallApp -.-> Core
  Core -->|REST & SSE| Server
  Admin -->|REST| Server
  Server -->|Prisma ORM| Postgres
  Server -->|node-redis| Redis
  Server <--> Agent
```

---

## 2. Core Architectural Decisions

### The Dual-Path Strategy
The system handles interactions using two independent, parallel lanes to guarantee speed and transactional consistency:
1. **Chat Path (Event-Driven)**: An asynchronous, stream-oriented path using AG-UI events over Server-Sent Events (SSE) from the Node backend to the Flutter customer chatbot.
2. **Seat Path (Transactional Polling)**: A concurrency-safe reservation flow using REST polling (`GET /shows/:id/seats`) backed by temporary Redis locks (holds) and final PostgreSQL database constraints.

### No Agent Framework (Hand-written Orchestrator)
The backend AI chatbot avoids black-box frameworks (like LangChain or LlamaIndex) in favor of a hand-written orchestration loop built directly on top of the Vercel AI SDK's low-level `streamText` primitive. Tool registration, context compaction, state patching, and sub-agent delegation are custom-coded for maximum control and security.

---

## 3. Workspace Inventory

| Directory | Subsystem / Role | Language / Tech Stack | Primary Responsibilities |
|---|---|---|---|
| [cinebook-server](file:///Users/mohittiwari/Dev/Cinebook/cinebook-server) | Backend Server | Node.js 22+, Express, TypeScript, Prisma, Redis | REST controllers, custom AI agent loop, database management, concurrency controls, rate limiting, and metrics. |
| [cinebook-admin](file:///Users/mohittiwari/Dev/Cinebook/cinebook-admin) | Admin Web App | React, Vite, TypeScript | Thin CRUD client for catalog overrides, role management, daily/weekly/monthly revenue charts, and auditing logs. |
| [cinebook_user_app](file:///Users/mohittiwari/Dev/Cinebook/cinebook_user_app) | Customer App | Flutter, Dart, BLoC pattern | Customer booking flow, real-time polling seat map, and the streaming AI chatbot interface using AG-UI events. |
| [cinebook_hall_app](file:///Users/mohittiwari/Dev/Cinebook/cinebook_hall_app) | Hall Manager App | Flutter, Dart, BLoC pattern | Calendar-based scheduling, screen configuration, and business rules constraint notifications. |
| [cinebook_core](file:///Users/mohittiwari/Dev/Cinebook/cinebook_core) | Shared package | Dart | Shared API client client (Dio), models (DTOs), and secure JWT storage (`flutter_secure_storage`). |

---

## 4. Getting Started

### Prerequisites
- **Node.js**: Version 22 or higher.
- **Flutter**: Stable SDK with Dart.
- **Docker & Docker Compose**: For running local Postgres and Redis.
- **OpenRouter API Key**: Required for the backend AI agent.

### Global Installation & Setup

1. **Start Infrastructure Services**:
   Navigate to [cinebook-server](file:///Users/mohittiwari/Dev/Cinebook/cinebook-server) and start the database and caching containers:
   ```bash
   cd cinebook-server
   docker-compose up -d
   ```

2. **Backend Server Setup**:
   Create a `.env` file inside `cinebook-server/` with your credentials:
   ```env
   DATABASE_URL="postgresql://postgres:postgres@localhost:5432/cinebook?schema=public"
   REDIS_URL="redis://localhost:6379"
   JWT_ACCESS_SECRET="your_jwt_access_secret_key"
   JWT_REFRESH_SECRET="your_jwt_refresh_secret_key"
   OPENROUTER_API_KEY="your_openrouter_api_key"
   PORT=3000
   ```
   Install dependencies, run database migrations, seed initial records, and start the development server:
   ```bash
   npm install
   npx prisma migrate dev
   npm run seed
   npm run dev
   ```

3. **Admin Web App Setup**:
   Navigate to [cinebook-admin](file:///Users/mohittiwari/Dev/Cinebook/cinebook-admin) to run the dashboard:
   ```bash
   cd ../cinebook-admin
   npm install
   npm run dev
   ```

4. **Flutter Clients Setup**:
   Pull pub packages for the shared library and the apps:
   ```bash
   # Shared core
   cd ../cinebook_core
   flutter pub get
   
   # Customer App
   cd ../cinebook_user_app
   flutter pub get
   flutter run
   
   # Hall Manager App
   cd ../cinebook_hall_app
   flutter pub get
   flutter run
   ```
```

- [ ] **Step 2: Verify root README file creation**

Verify that the file exists and can be read.
Run: `ls -la /Users/mohittiwari/Dev/Cinebook/README.md`
Expected: File details shown with non-zero size.

- [ ] **Step 3: Commit Root README**

```bash
git add README.md
git commit -m "docs: add root monorepo README with topology diagram"
```

---

### Task 2: Server README Documentation

**Files:**
- Create: `cinebook-server/README.md`

**Interfaces:**
- Produces: Detailed documentation of the server, database schemas, custom AI Agent loops, concurrency holds, and rate limit structures.

- [ ] **Step 1: Write server README file content**

Write the following contents to `/Users/mohittiwari/Dev/Cinebook/cinebook-server/README.md`:

```markdown
# CineBook Backend Server (`cinebook-server`)

The backend server is built using Node.js 22+, Express, and TypeScript. It uses Prisma ORM (with PostgreSQL) for persistent data storage and Redis for temporary seat holds, sliding window rate limits, and payment circuit-breaker state.

## 1. System Architecture

The server separates standard REST controller endpoints from the custom AI agent runtime. However, both pathways utilize the same underlying service layer to ensure business-rule consistency.

```mermaid
graph TD
  subgraph HTTP Routing
    Router[Express Router]
    AuthMW[Auth / RBAC Middleware]
  end

  subgraph Business Services
    MovieSvc[Movie Service]
    ShowSvc[Show Service]
    BookingSvc[Booking Service]
    PaymentSvc[Payment Service]
    HoldSvc[Hold Service]
  end

  subgraph Custom Agent Loop
    Orch[Custom Agent Orchestrator]
    Tools[26 Tools Registry]
    BookingAgent[Booking Assistant Sub-Agent]
    SSEEmitter[AG-UI SSE Emitter]
  end

  subgraph Infrastructure
    Prisma[Prisma Client]
    RedisClient[Redis Client]
  end

  Router --> AuthMW
  AuthMW --> MovieSvc
  AuthMW --> ShowSvc
  AuthMW --> BookingSvc
  AuthMW --> Orch

  Orch --> Tools
  Tools --> BookingAgent
  Tools --> MovieSvc
  Tools --> BookingSvc
  Tools --> HoldSvc
  Orch --> SSEEmitter
  SSEEmitter -->|SSE Stream| Client[Flutter User Client]

  MovieSvc --> Prisma
  ShowSvc --> Prisma
  BookingSvc --> Prisma
  HoldSvc --> RedisClient
  PaymentSvc --> RedisClient
```

---

## 2. Custom AI Agent Subsystem

The AI chatbot uses a custom loop written on top of the Vercel AI SDK (`ai@7`) communicating with OpenRouter. **No high-level agent frameworks are used.**

### Custom Orchestrator Loop (`orchestrator.ts`)
- **Execution Flow**: Low-level orchestration on `streamText`.
- **Context Compaction (`prepareStep`)**: Custom management of dialogue history. It summarizes older tool executions, removes redundant intermediate data, and restricts active tools based on the current conversational phase.
- **Conversation Logs**: Auto-persists system-wide JSON dialogue steps into the PostgreSQL `Conversation` and `Message` tables on completion (`onFinish`).

### The 26 Tools Registry
The orchestrator accesses 26 domain-specific tools, each defined with detailed Zod inputs:
- **Movie (10)**: `searchMovies`, `getMovieDetails`, `getCast`, `getReviews`, `getShowtimes`, `suggestSimilar`, `getTrending`, `getUpcoming`, `listLanguages`, `listGenres`
- **Booking (12)**: `findTheatres`, `getScreenInfo`, `checkSeatAvailability`, `holdSeats`, `releaseSeats`, `createBooking`, `checkBookingStatus`, `cancelBooking`, `viewBookingHistory`, `startPayment`, `confirmPayment`, `applyPromoCode`
- **Profile/Support (4)**: `getProfile`, `updatePreferences`, `getRecommendations`, `contactSupport`

### Sub-agent Delegation ("Booking Assistant")
- Under the main orchestrator, a single tool `delegateToBookingAssistant` acts as a sub-agent.
- It executes a secondary, restricted loop containing only booking-specific tools (`bookingToolsOnly`) with a strict step limit (12 steps).
- Once execution finishes, it returns a structured JSON result (`{ heldSeats, showId, holdExpiresAt, summary }`) back to the parent orchestrator.

### SSE Emitter Protocol (`agui-emitter.ts`)
The server converts raw stream parts from the Vercel AI SDK into client-facing AG-UI Server-Sent Events (SSE) at `POST /agent/run`:
- `text-delta` ➔ `TEXT_MESSAGE_CONTENT`
- `tool-call` ➔ `TOOL_CALL_START` (client displays shimmer loader)
- `tool-result` ➔ `TOOL_CALL_RESULT` (payload rendering native visual widgets)
- Context modification ➔ `STATE_SNAPSHOT` / `STATE_DELTA` (JSON patches updating local store)

---

## 3. Concurrency & Seat Locking

To guarantee that two users cannot book the same seat simultaneously, the server implements a high-throughput concurrency mechanism:

```mermaid
sequenceDiagram
  autonumber
  actor UserA as Customer A
  actor UserB as Customer B
  participant Redis
  participant Postgres

  Note over UserA, UserB: Attempting concurrent holds on Show S1, Seat 15A
  
  UserA->>Redis: SET seat:S1:15A ownerA NX PX 300000 (5-min hold)
  Redis-->>UserA: OK (Success)
  
  UserB->>Redis: SET seat:S1:15A ownerB NX PX 300000
  Redis-->>UserB: Nil (Failed - Key already exists)
  Note over UserB: Inform Customer B: Seat taken
  
  Note over UserA: Customer A proceeds to pay
  UserA->>Postgres: BEGIN TRANSACTION
  UserA->>Postgres: SELECT * FROM Show WHERE id = S1 FOR UPDATE
  UserA->>Redis: Check hold is still ownerA
  Redis-->>UserA: Yes (ownerA)
  UserA->>Postgres: INSERT INTO BookedSeat (showId, seatId, bookingId)
  Postgres-->>UserA: Success (Constraint Check Passed)
  UserA->>Postgres: COMMIT
  UserA->>Redis: Lua DEL seat:S1:15A if ownerA
  Redis-->>UserA: Deleted
```

### Steps:
1. **Hold (`holdSeats`)**: Uses Redis `SET seat:{showId}:{seatId} {ownerToken} NX PX 300000`. This sets a 5-minute TTL hold. If the key exists, the hold is rejected.
2. **Release (`releaseSeats`)**: Uses a Lua compare-and-delete script. This ensures a user can only release a seat if they own the active hold token.
3. **Confirm (`createBooking`)**:
   - Opens a PostgreSQL transaction.
   - Executes a row-level lock (`SELECT ... FOR UPDATE`) on the `Show` record or relies on DB constraints.
   - Re-checks that the Redis hold keys are still valid and owned by this transaction's user token.
   - Inserts records into `Booking` and `BookedSeat` tables.
   - Releases the Redis holds.
   - Database constraint `@@unique([showId, seatId])` on `BookedSeat` enforces final consistency.

---

## 4. Hall Manager Scheduling Rules

When creating or modifying shows via `ShowService`, the server enforces the following strict rules:
- **No Overlap**: A screen cannot host two shows at the same time.
- **Cleaning Gap**: There must be at least a 30-minute buffer gap between shows on the same screen.
- **Planning Window**: Shows cannot be scheduled more than 30 days in advance.
- **Screen Ownership**: The manager must be assigned to the screen they are scheduling (bypassed by admin overrides).
- **Edit Lock**: A show cannot be modified or deleted if it has at least one confirmed booking (`BookedSeat`).

---

## 5. Resiliency & Cross-Cutting Features

- **Observability**: Logs a unique correlation ID per request (via Node's `AsyncLocalStorage`). Every tool execution outputs execution latency, inputs, and state.
- **Sliding-Window Rate Limiter**: Implemented using Redis sorted sets (zsets) to track client API calls. Limits: chat 30/min/user, bookings 5/hr/user, phone OTP 5/hr/phone.
- **Payment Circuit Breaker**: Wraps the payment gateway. If payment attempts fail N consecutive times, the breaker trips to `OPEN` for a cooldown duration, returning immediate error responses. Breaker states are synchronized in Redis.

## 6. Setup & Commands

Ensure Docker is running, then use the following commands:
```bash
# Install packages
npm install

# Run migrations
npx prisma migrate dev

# Seed database
npm run seed

# Run tests
npm run test

# Start development server
npm run dev
```
```

- [ ] **Step 2: Verify server README file creation**

Verify that the file exists and can be read.
Run: `ls -la /Users/mohittiwari/Dev/Cinebook/cinebook-server/README.md`
Expected: File details shown.

- [ ] **Step 3: Commit Server README**

```bash
git add cinebook-server/README.md
git commit -m "docs: add cinebook-server README with detailed architecture and diagrams"
```

---

### Task 3: Core Package README Documentation

**Files:**
- Modify: `cinebook_core/README.md`

**Interfaces:**
- Produces: Setup and architectural guide for the shared Dart client.

- [ ] **Step 1: Write core README file content**

Write the following contents to `/Users/mohittiwari/Dev/Cinebook/cinebook_core/README.md` (overwriting the file):

```markdown
# CineBook Core Package (`cinebook_core`)

`cinebook_core` is a shared Dart plumbing package used by both the Customer App (`cinebook_user_app`) and the Hall Manager App (`cinebook_hall_app`). It abstracts network interactions, JWT authorization persistence, and data models to avoid codebase duplication.

## 1. Package Architecture

This package maintains a strict separation from the UI layers of the applications.

```
lib/
├── src/
│   ├── api/
│   │   ├── api_client.dart       # Dio HTTP client wrapper
│   │   └── endpoints.dart        # API routing dictionary
│   ├── auth/
│   │   └── token_storage.dart    # flutter_secure_storage client wrapper
│   └── models/                   # Standard deserializable Dart DTOs
│       ├── movie.dart
│       ├── show.dart
│       ├── seat.dart
│       └── booking.dart
└── cinebook_core.dart            # Primary library exports
```

---

## 2. Key Features

### Intercepted API Client
- Uses the `Dio` library wrapper for all network requests.
- Contains an authentication interceptor that automatically reads the access JWT from secure storage and injects it into request headers.
- Implements a retry interceptor. On receiving a `401 Unauthorized` status, it triggers a refresh-token call to `/auth/refresh` behind the scenes, updates the secure storage, and replays the failed request transparently.

### Secure Token Manager
- Uses `flutter_secure_storage` to persist tokens safely inside Android's KeyStore and iOS's Keychain.
- Manages persistence of User roles and session details so users remain logged in across application cold starts.

---

## 3. Usage Guide

To use this shared package in the Flutter applications, include it as a local path dependency in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cinebook_core:
    path: ../cinebook_core
```

Initialize the clients inside your main execution loop:
```dart
import 'package:cinebook_core/cinebook_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(
    baseUrl: 'http://localhost:3000',
    tokenStorage: tokenStorage,
  );

  runApp(MyApp(apiClient: apiClient));
}
```
```

- [ ] **Step 2: Verify core README file modification**

Verify that the file exists and can be read.
Run: `ls -la /Users/mohittiwari/Dev/Cinebook/cinebook_core/README.md`
Expected: File details shown.

- [ ] **Step 3: Commit Core README**

```bash
git add cinebook_core/README.md
git commit -m "docs: update shared core Dart package README"
```

---

### Task 4: Customer User App README Documentation

**Files:**
- Create: `cinebook_user_app/README.md`

**Interfaces:**
- Produces: Detailed documentation of the customer application, BLoC structure, SSE streaming parser, and periodic polling seat map.

- [ ] **Step 1: Write user app README file content**

Write the following contents to `/Users/mohittiwari/Dev/Cinebook/cinebook_user_app/README.md`:

```markdown
# CineBook Customer App (`cinebook_user_app`)

This is the customer-facing Flutter application. It allows users to browse movies, purchase tickets, view their booking history, and interact with the AI-powered reservation assistant.

## 1. Application Architecture

The application is structured around the BLoC (Business Logic Component) pattern for state management. It separates raw network requests (from `cinebook_core`) from the rendering layer.

```mermaid
graph TD
  subgraph UI Layer
    MoviesList[Movies List Screen]
    MovieDetail[Movie Detail Screen]
    SeatMap[Seat Map Screen]
    ChatAssistant[AI Chat Assistant Screen]
  end

  subgraph State Management (BLoC)
    MovieBloc[MovieBloc]
    SeatMapBloc[SeatMapBloc]
    ChatBloc[ChatBloc]
  end

  subgraph Data Layer
    CoreClient[cinebook_core ApiClient]
    SSEClient[Dio SSE Listener]
  end

  MoviesList --> MovieBloc
  MovieDetail --> MovieBloc
  SeatMap --> SeatMapBloc
  ChatAssistant --> ChatBloc

  MovieBloc --> CoreClient
  SeatMapBloc --> CoreClient
  ChatBloc --> SSEClient
```

---

## 2. Core Functional Flows

### AI Chat Event Processing (SSE to Rich Widgets)
The chatbot uses `flutter_gen_ai_chat_ui` (v2.14.0) to present a clean dialog box.
Since the tools run on the server, the client does not execute actions locally. Instead, the `ChatBloc` processes incoming SSE chunks from the server:

```mermaid
graph TD
  SSE[SSE Server Stream] -->|Chunk Events| Client[Dio Client]
  Client -->|Parse AG-UI JSON| Bloc[ChatBloc]
  
  subgraph Event Translation
    Bloc -->|TEXT_MESSAGE_CONTENT| TextWidget[Append Streaming Text Bubble]
    Bloc -->|TOOL_CALL_START| Shimmer[Show Loading Shimmer]
    Bloc -->|TOOL_CALL_RESULT| RichWidget[Render Native Widget]
    Bloc -->|STATE_SNAPSHOT / DELTA| Store[Update Client Booking Context Store]
  end
```

1. **Streaming Output**: Text deltas are appended to active text bubbles word-by-word.
2. **Action Indicator**: On `TOOL_CALL_START`, a visual shimmer is displayed (e.g. "checking availability...").
3. **Rich UI Insertion**: On `TOOL_CALL_RESULT`, the bloc swaps the loading shimmer with a native Flutter widget matching the tool's return type (e.g., rendering a clickable seat layout or movie info card).
4. **Context Synchronization**: Updates from `STATE_SNAPSHOT` or JSON diff patches (`STATE_DELTA`) are stored in the client-side booking context store, updating current selections and price totals.

### Real-Time Seat Map Polling
- When the Seat Map screen is active, `SeatMapBloc` starts a polling timer.
- It calls `GET /shows/:id/seats` every 2-3 seconds to fetch the merged state of PostgreSQL bookings and Redis holds.
- Seat states (Available, Held by Me, Held by Other, Booked) are visually color-coded.
- An overlay displays a 5-minute countdown representing the Redis hold expiration TTL.

---

## 3. Development & Running

1. **Verify Dependencies**: Ensure Flutter is installed and you are within the `cinebook_user_app/` directory.
2. **Fetch Packages**:
   ```bash
   flutter pub get
   ```
3. **Launch the App**:
   ```bash
   flutter run
   ```
```

- [ ] **Step 2: Verify user app README file creation**

Verify that the file exists and can be read.
Run: `ls -la /Users/mohittiwari/Dev/Cinebook/cinebook_user_app/README.md`
Expected: File details shown.

- [ ] **Step 3: Commit User App README**

```bash
git add cinebook_user_app/README.md
git commit -m "docs: add cinebook_user_app README detailing BLoC and SSE flows"
```

---

### Task 5: Hall App README Documentation

**Files:**
- Create: `cinebook_hall_app/README.md`

**Interfaces:**
- Produces: Setup and scheduling guidelines for the hall manager application.

- [ ] **Step 1: Write hall app README file content**

Write the following contents to `/Users/mohittiwari/Dev/Cinebook/cinebook_hall_app/README.md`:

```markdown
# CineBook Hall Manager App (`cinebook_hall_app`)

This is the manager-facing Flutter application. It allows screen managers to configure theater halls, schedule shows, and view schedules via a calendar interface.

## 1. Application Architecture

The application uses the BLoC pattern to manage screen layout states and calendar mutations.

```mermaid
graph TD
  subgraph UI Layer
    Dashboard[Screens Dashboard]
    Calendar[Show Calendar Screen]
    ShowEditor[Show Create/Edit Form]
  end

  subgraph State Management
    ScreenBloc[ScreenBloc]
    ShowSchedulerBloc[ShowSchedulerBloc]
  end

  subgraph Shared client
    CoreClient[cinebook_core ApiClient]
  end

  Dashboard --> ScreenBloc
  Calendar --> ShowSchedulerBloc
  ShowEditor --> ShowSchedulerBloc

  ScreenBloc --> CoreClient
  ShowSchedulerBloc --> CoreClient
```

---

## 2. Scheduling Flow & Business Validation

While the client provides user-friendly validation hints, the **server acts as the single source of truth** for all scheduling rules.

```mermaid
sequenceDiagram
  autonumber
  actor Manager
  participant UI as Calendar View
  participant Bloc as ShowSchedulerBloc
  participant Client as API Client (Dio)
  participant Server as Server Validation Engine

  Manager->>UI: Input Show details (Screen S1, Time 18:00)
  UI->>Bloc: CreateShowEvent
  Bloc->>Client: POST /shows
  Client->>Server: Request
  Note over Server: Run Scheduling Rules Check
  alt Overlap or <30 min Gap
    Server-->>Client: 400 Bad Request { error: "GAP_VIOLATION" }
    Client-->>Bloc: Exception(GAP_VIOLATION)
    Bloc-->>UI: ShowSchedulerErrorState ("Shows must have at least a 30-minute cleaning buffer.")
  else Checks Pass
    Server-->>Client: 201 Created { showId }
    Client-->>Bloc: ShowCreated
    Bloc-->>UI: ShowSchedulerSuccessState
  end
```

### Server Error Parsing
When the manager attempts to save a show schedule, the backend executes rule checks. If a conflict occurs, the server returns a specific error payload (e.g., code `OVERLAP_CONFLICT` or `GAP_VIOLATION`). The `ShowSchedulerBloc` catches the exception, maps the server code to localized warning messages, and displays them as floating Snackbars or form validation alerts.

---

## 3. Development Setup

1. **Fetch Packages**:
   ```bash
   flutter pub get
   ```
2. **Launch the App**:
   ```bash
   flutter run
   ```
```

- [ ] **Step 2: Verify hall app README file creation**

Verify that the file exists and can be read.
Run: `ls -la /Users/mohittiwari/Dev/Cinebook/cinebook_hall_app/README.md`
Expected: File details shown.

- [ ] **Step 3: Commit Hall App README**

```bash
git add cinebook_hall_app/README.md
git commit -m "docs: add cinebook_hall_app README with scheduling sequence"
```

---

### Task 6: Admin Dashboard README Documentation

**Files:**
- Modify: `cinebook-admin/README.md`

**Interfaces:**
- Produces: Structural details and running setup for the admin dashboard.

- [ ] **Step 1: Write admin app README file content**

Write the following contents to `/Users/mohittiwari/Dev/Cinebook/cinebook-admin/README.md` (overwriting the file):

```markdown
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
```

- [ ] **Step 2: Verify admin app README file modification**

Verify that the file exists and can be read.
Run: `ls -la /Users/mohittiwari/Dev/Cinebook/cinebook-admin/README.md`
Expected: File details shown.

- [ ] **Step 3: Commit Admin README**

```bash
git add cinebook-admin/README.md
git commit -m "docs: update admin dashboard README"
```
