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
