import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PassengerDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const PassengerDetailsScreen({super.key, required this.bookingData});

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _utrController = TextEditingController();

  String _gender = 'Male';
  int _passengersCount = 1;
  bool _termsAccepted = false;
  bool _isLoading = false;

  static const primaryColor = Color(0xFFD95325);
  static const fieldBg = Color(0xFFEBE8DF);

  @override
  void dispose() {
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _ageController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    if (_utrController.text.trim().length < 12 || !_termsAccepted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 12-digit UTR and accept Terms & Conditions'),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pickup = widget.bookingData['pickup'] ?? 'Bhopal';
      final drop = widget.bookingData['drop'] ?? 'Amarkantak';
      final days = widget.bookingData['days'] ?? 2;
      final totalFare = widget.bookingData['totalFare'] ?? 10800.0;
      final advanceFare = widget.bookingData['advanceFare'] ?? 5400.0;

      await Supabase.instance.client.from('bookings').insert({
        'pickup': pickup,
        'drop': drop,
        'days': days,
        'ac_type': widget.bookingData['acType'] ?? 'AC',
        'seat_type': widget.bookingData['seatType'] ?? '5 Seater',
        'trip_date': widget.bookingData['date'],
        'trip_time': widget.bookingData['time'],
        'distance_approx': widget.bookingData['distanceApprox'],
        'total_fare': totalFare,
        'advance_fare': advanceFare,
        'balance_fare': totalFare - advanceFare,
        'phone': _phoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim().isNotEmpty
            ? _whatsappController.text.trim()
            : _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'passenger_name': _fullNameController.text.trim(),
        'passenger_age': int.tryParse(_ageController.text.trim()) ?? 0,
        'gender': _gender,
        'passengers_count': _passengersCount,
        'utr': _utrController.text.trim(),
        'status': 'pending_verification',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking submitted successfully!')),
        );
        context.go('/my-bookings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save booking: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = widget.bookingData['pickup'] ?? 'Bhopal';
    final drop = widget.bookingData['drop'] ?? 'Amarkantak';
    final days = widget.bookingData['days'] ?? 2;
    final acType = widget.bookingData['acType'] ?? 'AC';
    final date = widget.bookingData['date'] ?? 'Tue, 22 Sep 2026';
    final time = widget.bookingData['time'] ?? '06:00';
    final approxKm = widget.bookingData['distanceApprox'] ?? 455;
    final totalFare = widget.bookingData['totalFare'] ?? 10800.0;
    final advanceFare = widget.bookingData['advanceFare'] ?? 5400.0;
    final balanceFare = totalFare - advanceFare;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            child: Icon(Icons.arrow_back, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Passenger Details & Pay',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '$pickup → $drop (Custom)',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary header banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E2D9)),
              ),
              child: Text(
                'Custom Cab • $days day(s) • $acType\n$date at $time • ${approxKm.toStringAsFixed(0)} km approx',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Contact Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E2D9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Phone Number'),
                  _customField(_phoneController, '10-digit mobile number'),
                  const SizedBox(height: 12),
                  _label('WhatsApp Number'),
                  _customField(_whatsappController, 'Leave same as phone if same'),
                  const SizedBox(height: 12),
                  _label('Email'),
                  _customField(_emailController, 'you@example.com'),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Passengers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Passenger Details Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E2D9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('Number of passengers'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (_passengersCount > 1) {
                                setState(() => _passengersCount--);
                              }
                            },
                          ),
                          Text(
                            '$_passengersCount',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => _passengersCount++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Passenger 1',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _label('Full name'),
                  _customField(_fullNameController, 'As per govt ID'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Age'),
                            _customField(_ageController, 'Age'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('Gender'),
                            const SizedBox(height: 6),
                            Row(
                              children: ['Male', 'Female', 'Other'].map((g) {
                                final sel = _gender == g;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: GestureDetector(
                                      onTap: () => setState(() => _gender = g),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: sel ? primaryColor : fieldBg,
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: Text(
                                          g,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: sel ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Fare Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Fare Summary Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E2D9)),
              ),
              child: Column(
                children: [
                  _summaryRow('Total fare', '₹${totalFare.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  _summaryRow('Advance now (50%)', '₹${advanceFare.toStringAsFixed(0)}', highlight: true),
                  const SizedBox(height: 8),
                  _summaryRow('Balance to driver at ride start', '₹${balanceFare.toStringAsFixed(0)}'),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Pay Advance via UPI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // QR & UTR Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E2D9)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Scan with any UPI app',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.qr_code_2, size: 140),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'UPI ID: rcmitra@upi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Amount to pay: ₹${advanceFare.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Divider(height: 28),
                  _label('12-digit UTR / UPI Reference Number'),
                  _customField(_utrController, 'e.g. 123456789012'),
                  const SizedBox(height: 8),
                  const Text(
                    'After paying, copy the 12-digit UTR number from your UPI app and paste it here. Our team verifies it before confirming your ticket.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Terms & Conditions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Terms Checkbox Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E2D9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _termsAccepted,
                        activeColor: primaryColor,
                        onChanged: (val) => setState(() => _termsAccepted = val ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'I accept the Terms & Conditions',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Terms & Conditions'),
                          content: const Text(
                            '1. 50% advance non-refundable after vehicle assignment.\n2. Toll, parking, and state tax paid separately by customer.\n3. Driver bath/food allowance included as per standard intercity contract.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(left: 12.0),
                      child: Text(
                        'Read full terms',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Confirm Booking • Pay ₹${advanceFare.toStringAsFixed(0)} Advance',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    );
  }

  Widget _customField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: fieldBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: highlight ? primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }
}