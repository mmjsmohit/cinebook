# A2UI Stretch - Generative Booking Preferences Form Design

## Overview
Implement Google's declarative generative-UI (A2UI v0.9.1) concept to render a custom booking preferences form in the Flutter app chat UI, composed from a trusted client catalog of widgets. Tapping submit sends a structured JSON message back to the agent.

## Backend Changes
- **Tools**: Add `requestPreferencesForm` in `cinebook-server/src/agent/tools/profileTools.ts` inside `createProfileTools`.
  - **Input**: `z.object({})`
  - **Output**: Returns JSON containing `renderHint: "a2ui"`, `surfaceId`, and a declarative description of components (DatePicker, TimeOfDay selection, PartySize counter, and SeatCategory dropdown).
- **System Prompt**: Update `cinebook-server/src/agent/prompts.ts` to instruct the agent on how to handle the `booking_preferences_submitted` JSON event message.

## Frontend Changes
- **Widget Catalog**: Create a new custom widget in `cinebook_user_app/lib/widgets/a2ui_form.dart` that takes the components JSON and dynamically builds the form using:
  - Date picker dialog.
  - Dropdown for Time of Day (Morning, Afternoon, Evening, Night).
  - Counter widget for Party Size (1 to 10).
  - Dropdown for Seating Category (Standard, Premium, Recliner).
- **Bloc Event**: Update `ChatSendMessage` or handle form submission directly in `AgentScreen` by dispatching `ChatSendMessage` with the JSON string representing the submission event.
- **AiChatWidget Integration**: Update the `resultRenderers` map in [agent_screen.dart](file:///Users/mohittiwari/Dev/Cinebook/cinebook_user_app/lib/screens/agent_screen.dart) to map `"a2ui"` to the `A2UiForm` widget.

## Data Flow
1. User requests form (e.g. "I want to set my search preferences").
2. Agent calls `requestPreferencesForm` tool.
3. Tool outputs A2UI JSON payload.
4. Client parses the payload and renders the custom form in the chat stream.
5. User selects values and taps "Submit".
6. Client stringifies the event and dispatches a standard text message back:
   `{"event": "booking_preferences_submitted", "data": {"date": "YYYY-MM-DD", "timeOfDay": "...", "partySize": X, "seatCategory": "..."}}`
7. Agent parses this JSON string, updates its conversation state, and lists matching showtimes.
