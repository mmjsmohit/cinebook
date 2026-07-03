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
