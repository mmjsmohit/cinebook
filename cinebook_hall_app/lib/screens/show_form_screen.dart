import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'package:dio/dio.dart';

class ShowFormScreen extends StatefulWidget {
  final String screenId;
  final Map<String, dynamic>? showData; 

  const ShowFormScreen({super.key, required this.screenId, this.showData});

  @override
  State<ShowFormScreen> createState() => _ShowFormScreenState();
}

class _ShowFormScreenState extends State<ShowFormScreen> {
  final _movieIdController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _languageController = TextEditingController(text: 'EN');
  final _formatController = TextEditingController(text: '2D');
  final _priceController = TextEditingController(text: '1.0');
  
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.showData != null) {
      _movieIdController.text = widget.showData!['movieId'] ?? '';
      _startTimeController.text = widget.showData!['startTime'] ?? '';
      _languageController.text = widget.showData!['language'] ?? 'EN';
      _formatController.text = widget.showData!['format'] ?? '2D';
      _priceController.text = widget.showData!['priceMultiplier']?.toString() ?? '1.0'; 
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final api = context.read<ApiClient>();
      final data = {
        'movieId': _movieIdController.text,
        'startTime': _startTimeController.text, 
        'language': _languageController.text,
        'format': _formatController.text,
        'priceMultiplier': double.tryParse(_priceController.text) ?? 1.0,
      };

      if (widget.showData == null) {
        data['screenId'] = widget.screenId;
        await api.dio.post('/screens/${widget.screenId}/shows', data: data);
      } else {
        await api.dio.patch('/shows/${widget.showData!['id']}', data: data);
      }

      if (mounted) Navigator.pop(context);
    } on DioException catch (e) {
      String msg = 'Failed to save show';
      if (e.response?.data != null && e.response!.data is Map) {
        final err = (e.response!.data as Map)['error'];
        if (err != null) {
          msg = err['message'] ?? msg;
          if (err['code'] == 'SHOW_OVERLAP') msg = 'Error: Show overlaps with an existing show.';
          if (err['code'] == 'INSUFFICIENT_CLEANING_GAP') msg = 'Error: Insufficient cleaning gap (need 30m).';
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.showData == null ? 'Create Show' : 'Edit Show')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: CinemaColors.neonRed.withValues(alpha: 0.1),
                child: Text(_errorMessage!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: CinemaColors.neonRed)),
              ),
            TextField(
              controller: _movieIdController,
              decoration: const InputDecoration(labelText: 'Movie ID'),
            ),
            TextField(
              controller: _startTimeController,
              decoration: const InputDecoration(labelText: 'Start Time (ISO8601)', hintText: '2026-07-01T14:30:00Z'),
            ),
            TextField(
              controller: _languageController,
              decoration: const InputDecoration(labelText: 'Language (EN, HI, etc)'),
            ),
            TextField(
              controller: _formatController,
              decoration: const InputDecoration(labelText: 'Format (2D, 3D, IMAX)'),
            ),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price Multiplier'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            if (_isSaving) const CircularProgressIndicator()
            else ElevatedButton(
              onPressed: _save,
              child: const Text('Save Show'),
            ),
          ],
        ),
      ),
    );
  }
}
