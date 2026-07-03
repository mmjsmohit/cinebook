# Checkout Promo Integration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to apply promo codes during checkout on the Payment screen by consuming the `/promo/validate` (or `/promo`) API, and redesign the checkout screen to match the SeatGeek modal reference.

**Architecture:** We will redesign `payment_screen.dart` to a bottom-heavy modal structure. A new text field for Promo Code will be added. When a code is applied, the UI state will update to show the discount and adjust the total (or just successfully validate it before finalizing the booking).

**Tech Stack:** Flutter, Dio

## Global Constraints

- All colors must come from `CinemaColors` or `Theme.of(context)`. Zero raw `Colors.*` or `Color(0xFF...)` in screen files.
- Typography must use `Theme.of(context).textTheme.*` everywhere.
- Run `flutter analyze` after every task to verify zero analysis errors.

---

### Task 1: Add Promo Code Validation and Redesign Payment Screen

**Files:**
- Modify: `/Users/mohittiwari/Dev/Cinebook/cinebook_user_app/lib/screens/payment_screen.dart`

**Interfaces:**
- Consumes: `/promo/validate` API (or equivalent backend route for promo codes)

- [ ] **Step 1: Update State in `payment_screen.dart`**
Add text controller for the promo code and state variables for the applied discount.

```dart
// inside _PaymentScreenState
  final TextEditingController _promoController = TextEditingController();
  bool _isApplyingPromo = false;
  String? _appliedPromoCode;
  String? _promoMessage;

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isApplyingPromo = true);
    try {
      final api = context.read<ApiClient>();
      // Assuming a generic POST /promo/validate endpoint exists
      // If it doesn't, this will just throw an error which is caught.
      // Update this endpoint to match the exact promo API once verified in backend.
      final res = await api.dio.post('/promo/validate', data: {'code': code});
      setState(() {
        _appliedPromoCode = code;
        _promoMessage = 'Promo code applied successfully!';
        _isApplyingPromo = false;
      });
    } catch (e) {
      setState(() {
        _promoMessage = 'Invalid promo code';
        _isApplyingPromo = false;
      });
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }
```

- [ ] **Step 2: Redesign `build` method in `payment_screen.dart`**
Change the generic screen into a clean checkout UI similar to SeatGeek's Checkout modal reference.

```dart
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
                                color: _appliedPromoCode != null ? Colors.green : CinemaColors.neonRed),
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
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _processPayment,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Pay Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
```

- [ ] **Step 3: Modify backend payload if needed**
If `_appliedPromoCode` is not null, pass it to the `/payments` API call in `_processPayment()`.

```dart
// Modify the /payments POST call in _processPayment:
      await api.dio.post('/payments', data: {
        'bookingId': bookingId,
        'cardNumber': '4000', 
        if (_appliedPromoCode != null) 'promoCode': _appliedPromoCode,
      });
```

- [ ] **Step 4: Verify static analysis**
Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 5: Commit**
```bash
git add cinebook_user_app/lib/screens/payment_screen.dart
git commit -m "feat: redesign checkout screen and add promo code support"
```
