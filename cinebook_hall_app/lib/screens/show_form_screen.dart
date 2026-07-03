import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../widgets/movie_search_field.dart';

class ShowFormScreen extends StatefulWidget {
  final String screenId;
  final Map<String, dynamic>? showData;
  const ShowFormScreen({super.key, required this.screenId, this.showData});

  @override
  State<ShowFormScreen> createState() => _ShowFormScreenState();
}

class _ShowFormScreenState extends State<ShowFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _movieId;
  String? _movieTitle;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _language = 'English';
  String _format = '2D';
  final _priceController = TextEditingController(text: '20000');
  
  bool _isSaving = false;
  String? _errorMessage;

  static const _languages = ['English', 'Hindi', 'Tamil', 'Telugu', 'Kannada', 'Malayalam', 'Korean', 'Japanese', 'Spanish', 'French'];
  static const _formats = ['2D', '3D', 'IMAX', '4DX', 'DOLBY_ATMOS'];

  bool get _isEditing => widget.showData != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final show = widget.showData!;
      _movieId = show['movieId'];
      _movieTitle = show['movie']?['title'];
      final startTime = DateTime.parse(show['startTime']);
      _selectedDate = startTime;
      _selectedTime = TimeOfDay.fromDateTime(startTime);
      _language = show['language'] ?? 'English';
      _format = show['format'] ?? '2D';
      _priceController.text = show['basePrice']?.toString() ?? '20000';
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String? _buildIsoString() {
    if (_selectedDate == null || _selectedTime == null) return null;
    final dt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    return dt.toUtc().toIso8601String();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_movieId == null) {
      setState(() => _errorMessage = 'Please select a movie');
      return;
    }
    final isoString = _buildIsoString();
    if (isoString == null) {
      setState(() => _errorMessage = 'Please select both date and time');
      return;
    }

    setState(() { _isSaving = true; _errorMessage = null; });

    try {
      final api = context.read<ApiClient>();
      final data = {
        'movieId': _movieId,
        'startTime': isoString,
        'language': _language,
        'format': _format,
        'basePrice': int.tryParse(_priceController.text) ?? 20000,
      };

      if (!_isEditing) {
        data['screenId'] = widget.screenId;
        await api.dio.post('/screens/${widget.screenId}/shows', data: data);
      } else {
        await api.dio.patch('/shows/${widget.showData!['id']}', data: data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Show updated!' : 'Show created!')),
        );
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      String msg = 'Failed to save show';
      if (e.response?.data != null && e.response!.data is Map) {
        final err = (e.response!.data as Map)['error'];
        if (err != null) {
          msg = err['message'] ?? msg;
          if (err['code'] == 'OVERLAP') msg = 'This show overlaps with an existing show.';
          if (err['code'] == 'GAP_TOO_SHORT') msg = 'Need at least 30 min gap between shows.';
        }
      }
      setState(() => _errorMessage = msg);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Show' : 'Create Show')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error banner
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: CinemaColors.neonRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CinemaColors.neonRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: CinemaColors.neonRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!, style: theme.textTheme.bodyMedium?.copyWith(color: CinemaColors.neonRed)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: CinemaColors.neonRed),
                        onPressed: () => setState(() => _errorMessage = null),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),

              // Movie search
              Text('Movie', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              MovieSearchField(
                initialMovieId: _movieId,
                initialMovieTitle: _movieTitle,
                onMovieSelected: (movie) {
                  setState(() {
                    _movieId = movie['id'];
                    _movieTitle = movie['title'];
                  });
                },
              ),
              const SizedBox(height: 24),

              // Date & Time pickers
              Text('Schedule', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate != null ? dateFormat.format(_selectedDate!) : 'Select date',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _selectedDate != null ? CinemaColors.offWhite : CinemaColors.steelGray,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _selectedTime != null ? _selectedTime!.format(context) : 'Select time',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: _selectedTime != null ? CinemaColors.offWhite : CinemaColors.steelGray,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Language & Format dropdowns
              Text('Details', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _language,
                      decoration: const InputDecoration(labelText: 'Language'),
                      items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                      onChanged: (v) => setState(() => _language = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _format,
                      decoration: const InputDecoration(labelText: 'Format'),
                      items: _formats.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (v) => setState(() => _format = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Base price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Base Price (paise)',
                  prefixIcon: Icon(Icons.currency_rupee),
                  helperText: 'Price in paise. 20000 = ₹200',
                ),
                keyboardType: const TextInputType.numberWithOptions(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Enter a valid number';
                  if (int.parse(v) <= 0) return 'Must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save button
              if (_isSaving)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  onPressed: _save,
                  icon: Icon(_isEditing ? Icons.save : Icons.add),
                  label: Text(_isEditing ? 'Update Show' : 'Create Show'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
