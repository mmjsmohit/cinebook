import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String showId;
  final List<String> seatIds;

  const PaymentScreen({super.key, required this.showId, required this.seatIds});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  final TextEditingController _promoController = TextEditingController();
  bool _isApplyingPromo = false;
  String? _appliedPromoCode;
  String? _promoMessage;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isApplyingPromo = true);
    try {
      final api = context.read<ApiClient>();
      
      await api.dio.post('/promo/validate', data: {'code': code});
      if (!mounted) return;
      setState(() {
        _appliedPromoCode = code;
        _promoMessage = 'Promo code applied successfully!';
        _isApplyingPromo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _promoMessage = 'Invalid promo code';
        _isApplyingPromo = false;
      });
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    try {
      final api = context.read<ApiClient>();
      
      final holdRes = await api.dio.post('/shows/${widget.showId}/holds', data: {
        'seatIds': widget.seatIds,
      });
      final holdToken = holdRes.data['holdToken'];

      final bookRes = await api.dio.post('/bookings', data: {
        'showId': widget.showId,
        'seatIds': widget.seatIds,
        'holdToken': holdToken,
      });
      final bookingId = bookRes.data['bookingId'];

      await Future.delayed(const Duration(seconds: 2));

      await api.dio.post('/payments', data: {
        'bookingId': bookingId,
        'cardNumber': '4000', 
        if (_appliedPromoCode != null) 'promoCode': _appliedPromoCode,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ConfirmationScreen(bookingId: bookingId)),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing Payment...'),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Quantity', style: Theme.of(context).textTheme.titleMedium),
                        trailing: Text('${widget.seatIds.length} E-Ticket(s)', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text('Promo Code', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promoController,
                              decoration: const InputDecoration(
                                hintText: 'Enter code',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isApplyingPromo ? null : _applyPromo,
                            child: _isApplyingPromo ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Apply'),
                          ),
                        ],
                      ),
                      if (_promoMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _promoMessage!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _appliedPromoCode != null ? CinemaColors.successGreen : CinemaColors.neonRed),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            Text('View Details', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: CinemaColors.neonRed,
                            foregroundColor: CinemaColors.offWhite,
                          ),
                          onPressed: _processPayment,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text('Pay Now', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
