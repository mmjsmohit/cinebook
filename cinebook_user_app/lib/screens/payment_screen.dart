import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cinebook_core/cinebook_core.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String showId;
  final List<String> seatIds;

  const PaymentScreen({super.key, required this.showId, required this.seatIds});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _showDetails;
  
  final TextEditingController _promoController = TextEditingController();
  bool _isApplyingPromo = false;
  String? _appliedPromoCode;
  String? _promoMessage;
  
  String _selectedPaymentMethod = 'upi';

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
    _promoController.addListener(() {
      if (_appliedPromoCode != null && _promoController.text.trim() != _appliedPromoCode) {
        setState(() {
          _appliedPromoCode = null;
          _promoMessage = null;
        });
      }
    });
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final api = context.read<ApiClient>();
      final res = await api.dio.get('/shows/${widget.showId}');
      if (mounted) {
        setState(() {
          _showDetails = res.data['show'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: CinemaColors.neonRed));
      }
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isApplyingPromo = true;
      _appliedPromoCode = null;
      _promoMessage = null;
    });
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
        _appliedPromoCode = null;
        _promoMessage = 'Invalid promo code';
        _isApplyingPromo = false;
      });
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);
    try {
      final api = context.read<ApiClient>();
      
      // Hold seats
      final holdRes = await api.dio.post('/shows/${widget.showId}/holds', data: {
        'seatIds': widget.seatIds,
      });
      final holdToken = holdRes.data['holdToken'];

      // Create Booking
      final bookRes = await api.dio.post('/bookings', data: {
        'showId': widget.showId,
        'seatIds': widget.seatIds,
        'holdToken': holdToken,
      });
      final bookingId = bookRes.data['bookingId'];

      // Simulate network processing animation
      await Future.delayed(const Duration(seconds: 2));

      // Process Payment
      await api.dio.post('/payments', data: {
        'bookingId': bookingId,
        'cardNumber': '4000', 
        if (_appliedPromoCode != null) 'promoCode': _appliedPromoCode,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, _, _) => ConfirmationScreen(bookingId: bookingId),
            transitionsBuilder: (_, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: CinemaColors.neonRed));
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Assuming a static price per ticket for UI demo if not returned by API
  double _calculateTotal() {
    double basePrice = 250.0 * widget.seatIds.length;
    double tax = basePrice * 0.18;
    double discount = _appliedPromoCode != null ? 50.0 : 0.0;
    return basePrice + tax - discount;
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return _buildProcessingScreen();
    }

    return Scaffold(
      backgroundColor: CinemaColors.deepCharcoal,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: CinemaColors.deepCharcoal,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: CinemaColors.neonRed))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildOrderSummaryCard(),
                        const SizedBox(height: 24),
                        _buildPromoSection(),
                        const SizedBox(height: 24),
                        _buildPaymentMethods(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildProcessingScreen() {
    return Scaffold(
      backgroundColor: CinemaColors.deepCharcoal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: CinemaColors.neonRed,
              strokeWidth: 3,
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'Processing Payment...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: CinemaColors.offWhite,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Text(
              'Please do not close the app or press back',
              style: TextStyle(color: CinemaColors.steelGray),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    if (_showDetails == null) return const SizedBox();
    
    final movie = _showDetails!['movie'];
    final screen = _showDetails!['screen'];
    final theatre = screen['theatre'];
    final startTime = DateTime.parse(_showDetails!['startTime']).toLocal();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: CinemaColors.inkCharcoal.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CinemaColors.structuralBorder),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (movie['posterUrl'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          movie['posterUrl'],
                          width: 80,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_,_,_) => const SizedBox(width: 80, height: 120, child: ColoredBox(color: CinemaColors.deepCharcoal)),
                        ),
                      )
                    else
                      const SizedBox(width: 80, height: 120, child: ColoredBox(color: CinemaColors.deepCharcoal)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie['title'] ?? 'Movie',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: CinemaColors.offWhite,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_showDetails!['format']} • ${_showDetails!['language']}',
                            style: const TextStyle(color: CinemaColors.steelGray, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            theatre['name'] ?? 'Theatre',
                            style: const TextStyle(color: CinemaColors.offWhite),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEE, d MMM yyyy • hh:mm a').format(startTime),
                            style: const TextStyle(color: CinemaColors.offWhite),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: CinemaColors.deepCharcoal,
                  border: Border(top: BorderSide(color: CinemaColors.structuralBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.seatIds.length} Ticket(s)',
                      style: const TextStyle(color: CinemaColors.steelGray, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'View Seat Details',
                      style: TextStyle(color: CinemaColors.warmAmber, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildPromoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offers & Promos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: CinemaColors.offWhite,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promoController,
                style: const TextStyle(color: CinemaColors.offWhite),
                decoration: InputDecoration(
                  hintText: 'Enter Promo Code',
                  hintStyle: const TextStyle(color: CinemaColors.steelGray),
                  filled: true,
                  fillColor: CinemaColors.inkCharcoal,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: CinemaColors.structuralBorder, width: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isApplyingPromo ? null : _applyPromo,
              style: ElevatedButton.styleFrom(
                backgroundColor: CinemaColors.structuralBorder,
                foregroundColor: CinemaColors.offWhite,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isApplyingPromo 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: CinemaColors.offWhite)) 
                  : const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (_promoMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0, left: 4),
            child: Row(
              children: [
                Icon(
                  _appliedPromoCode != null ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: _appliedPromoCode != null ? CinemaColors.successGreen : CinemaColors.neonRed,
                ),
                const SizedBox(width: 8),
                Text(
                  _promoMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _appliedPromoCode != null ? CinemaColors.successGreen : CinemaColors.neonRed,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: CinemaColors.offWhite,
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentOption('upi', 'UPI / Apps', Icons.qr_code_scanner),
        const SizedBox(height: 12),
        _buildPaymentOption('card', 'Credit / Debit Card', Icons.credit_card),
        const SizedBox(height: 12),
        _buildPaymentOption('netbanking', 'Net Banking', Icons.account_balance),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildPaymentOption(String value, String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? CinemaColors.neonRed.withValues(alpha: 0.1) : CinemaColors.inkCharcoal,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? CinemaColors.neonRed : CinemaColors.structuralBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? CinemaColors.neonRed : CinemaColors.steelGray),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? CinemaColors.offWhite : CinemaColors.steelGray,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: CinemaColors.neonRed),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final total = _calculateTotal();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CinemaColors.inkCharcoal,
        border: const Border(top: BorderSide(color: CinemaColors.structuralBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount Payable', style: TextStyle(color: CinemaColors.steelGray, fontSize: 16)),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: CinemaColors.offWhite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: CinemaColors.neonRed,
                foregroundColor: CinemaColors.offWhite,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                shadowColor: CinemaColors.neonRed.withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Confirm Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
