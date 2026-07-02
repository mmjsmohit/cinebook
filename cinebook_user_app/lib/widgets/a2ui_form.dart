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
