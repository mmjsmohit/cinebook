# A2UI Stretch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement A2UI generative preferences form tool on backend and render dynamically in Flutter app.

**Architecture:** We will implement `requestPreferencesForm` tool on the server. The Flutter app will register `"a2ui"` renderer to render a dynamic form based on the components list. On submission, the form sends a JSON stringified user message back to the agent.

**Tech Stack:** Node.js, Express, AI SDK, Flutter, Dart

## Global Constraints

- Do not break existing chat streaming or booking context mechanisms.
- All dynamic UI components must utilize pre-approved native Flutter widgets (catalog security boundary).

---

### Task 1: Backend Tool & Prompt

**Files:**
- Modify: `cinebook-server/src/agent/tools/profileTools.ts`
- Modify: `cinebook-server/src/agent/prompts.ts`

**Interfaces:**
- Produces: `requestPreferencesForm` tool.
- Produces: System prompt instructions for A2UI event.

- [ ] **Step 1: Implement requestPreferencesForm tool**

Open `cinebook-server/src/agent/tools/profileTools.ts` and add `requestPreferencesForm` at the end of the `createProfileTools` factory:

```typescript
    requestPreferencesForm: tool({
      description:
        "Show an interactive preferences form to collect user booking filters (date, time, party size, seat category). Use this tool when the user wants to set search preferences, search parameters, or asks to fill in details.",
      inputSchema: z.object({}),
      execute: withToolLogger('requestPreferencesForm', async () => {
        return {
          renderHint: 'a2ui' as const,
          surfaceId: 'booking-preferences-form',
          components: [
            {
              type: 'form',
              id: 'pref_form',
              children: [
                {
                  type: 'datePicker',
                  id: 'date',
                  label: 'Show Date',
                  required: true,
                },
                {
                  type: 'timePicker',
                  id: 'time',
                  label: 'Preferred Time of Day',
                  required: true,
                },
                {
                  type: 'counter',
                  id: 'partySize',
                  label: 'Number of Tickets (Party Size)',
                  min: 1,
                  max: 10,
                  defaultValue: 2,
                },
                {
                  type: 'dropdown',
                  id: 'seatCategory',
                  label: 'Preferred Seating Category',
                  options: ['NORMAL', 'PREMIUM', 'RECLINER'],
                  defaultValue: 'NORMAL',
                },
              ],
            },
          ],
        };
      }),
    }),
```

- [ ] **Step 2: Update System Prompt**

Open `cinebook-server/src/agent/prompts.ts`. Modify `buildSystemPrompt` to add a section instructing the agent on handling the JSON submission event.

Add to system prompt instructions:
```typescript
- IMPORTANT: If the user message is a JSON string with "event": "booking_preferences_submitted", parse it. The event provides preferred booking filters (date, timeOfDay, partySize, seatCategory). Treat this as the user submitting their preferences. Immediately use getShowtimes with the parsed date to search for available shows, and inform the user of matching options. If the event does not contain a specific movie, ask the user which movie they would like to watch for these preferences.
```

- [ ] **Step 3: Commit backend tool changes**

```bash
git add cinebook-server/src/agent/tools/profileTools.ts cinebook-server/src/agent/prompts.ts
git commit -m "feat(api): add requestPreferencesForm tool and system instructions"
```

---

### Task 2: Frontend A2UI Widget Catalog

**Files:**
- Create: `cinebook_user_app/lib/widgets/a2ui_form.dart`

**Interfaces:**
- Produces: `A2UiForm` widget with dynamic form rendering and `onSubmit` callback.

- [ ] **Step 1: Implement A2UiForm Widget**

Create `cinebook_user_app/lib/widgets/a2ui_form.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class A2UiForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic> values) onSubmit;

  const A2UiForm({
    super.key,
    required this.data,
    required this.onSubmit,
  });

  @override
  State<A2UiForm> createState() => _A2UiFormState();
}

class _A2UiFormState extends State<A2UiForm> {
  DateTime? _selectedDate;
  String _timeOfDay = 'EVENING';
  int _partySize = 2;
  String _seatCategory = 'NORMAL';

  @override
  void initState() {
    super.initState();
    // Parse default values from components if present
    final components = widget.data['components'] as List<dynamic>? ?? [];
    for (final comp in components) {
      if (comp['type'] == 'form') {
        final children = comp['children'] as List<dynamic>? ?? [];
        for (final child in children) {
          final id = child['id'];
          final defaultValue = child['defaultValue'];
          if (id == 'partySize' && defaultValue is num) {
            _partySize = defaultValue.toInt();
          } else if (id == 'seatCategory' && defaultValue is String) {
            _seatCategory = defaultValue;
          }
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter Booking Preferences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Date Picker Field
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Date'),
              subtitle: Text(
                _selectedDate == null
                    ? 'Tap to select date'
                    : DateFormat('yyyy-MM-dd').format(_selectedDate!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const Divider(),

            // Time of Day Dropdown
            DropdownButtonFormField<String>(
              value: _timeOfDay,
              decoration: const InputDecoration(labelText: 'Preferred Time'),
              items: ['MORNING', 'AFTERNOON', 'EVENING', 'NIGHT']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _timeOfDay = val);
              },
            ),
            const SizedBox(height: 16),

            // Seating Category Dropdown
            DropdownButtonFormField<String>(
              value: _seatCategory,
              decoration: const InputDecoration(labelText: 'Seat Category'),
              items: ['NORMAL', 'PREMIUM', 'RECLINER']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _seatCategory = val);
              },
            ),
            const SizedBox(height: 16),

            // Party Size Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tickets (Party Size)'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _partySize > 1
                          ? () => setState(() => _partySize--)
                          : null,
                    ),
                    Text(
                      '$_partySize',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _partySize < 10
                          ? () => setState(() => _partySize++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedDate == null
                    ? null
                    : () {
                        widget.onSubmit({
                          'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
                          'timeOfDay': _timeOfDay,
                          'partySize': _partySize,
                          'seatCategory': _seatCategory,
                        });
                      },
                child: const Text('Submit Preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit Widget addition**

```bash
git add cinebook_user_app/lib/widgets/a2ui_form.dart
git commit -m "feat(app): add A2UiForm widget"
```

---

### Task 3: UI Integration

**Files:**
- Modify: `cinebook_user_app/lib/screens/agent_screen.dart`

**Interfaces:**
- Consumes: `"a2ui"` result render kind.

- [ ] **Step 1: Import A2UiForm and Register Result Renderer**

Open `cinebook_user_app/lib/screens/agent_screen.dart`.
Add import:
```dart
import '../widgets/a2ui_form.dart';
```

In the `AiChatWidget` definition, add the `'a2ui'` renderer to `resultRenderers`:

```dart
                      resultRenderers: {
                        'a2ui': (ctx, data) {
                          return A2UiForm(
                            data: data,
                            onSubmit: (values) {
                              bloc.add(ChatSendMessage(jsonEncode({
                                'event': 'booking_preferences_submitted',
                                'data': values,
                              })));
                            },
                          );
                        },
                        'movieList': (ctx, data) => _buildMovieList(data),
                        // ...
```

- [ ] **Step 2: Commit UI integration**

```bash
git add cinebook_user_app/lib/screens/agent_screen.dart
git commit -m "feat(app): integrate A2UiForm inside AgentScreen"
```
