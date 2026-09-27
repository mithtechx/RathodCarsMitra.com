import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PassengerInfo {
  final String seat;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String gender = 'Male';

  PassengerInfo(this.seat);

  void dispose() {
    nameController.dispose();
    ageController.dispose();
  }
}

class PassengerPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  const PassengerPaymentScreen({super.key, required this.bookingData});

  @override
  State<PassengerPaymentScreen> createState() => _PassengerPaymentScreenState();
}

class _PassengerPaymentScreenState extends State<PassengerPaymentScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _utrController = TextEditingController();

  bool _acceptTerms = false;
  bool _isLoading = false;
  late final List<PassengerInfo> _passengers;

  static const primaryColor = Color(0xFFD95325);
  static const fieldBg = Color(0xFFEBE8DF);

  @override
  void initState() {
    super.initState();
    final seatsList = (widget.bookingData['selectedSeats'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        ['1A'];
    _passengers = seatsList.map((seat) => PassengerInfo(seat)).toList();

    _utrController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _utrController.dispose();
    for (var p in _passengers) {
      p.dispose();
    }
    super.dispose();
  }

  bool _isFormValid() {
    if (_phoneController.text.trim().length < 10) return false;
    if (_utrController.text.trim().length < 10) return false;
    if (!_acceptTerms) return false;
    for (var p in _passengers) {
      if (p.nameController.text.trim().isEmpty) return false;
    }
    return true;
  }

  String _generatePnr() {
    final randomNum = 1000 + DateTime.now().millisecondsSinceEpoch % 90000;
    return 'RC-2026-$randomNum';
  }

  Future<void> _submitBooking() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final from = widget.bookingData['from'] ?? 'Bhopal';
      final to = widget.bookingData['to'] ?? 'Jabalpur';
      final totalAmount = int.tryParse(widget.bookingData['totalAmount']?.toString() ?? '1498') ?? 1498;
      final advanceAmount = int.tryParse(widget.bookingData['advanceAmount']?.toString() ?? '749') ?? 749;
      
      final pnrNumber = _generatePnr();
      final primaryPassengerName = _passengers.first.nameController.text.trim();
      final phone = _phoneController.text.trim();
      final utr = _utrController.text.trim();

      // Insert booking into Supabase database
      await supabase.from('bookings').insert({
        'pnr_number': pnrNumber,
        'passenger_name': primaryPassengerName,
        'passenger_phone': phone,
        'pickup_location': from,
        'drop_location': to,
        'seats': _passengers.map((p) => p.seat).join(', '),
        'total_amount': totalAmount,
        'fare': totalAmount,
        'advance_amount': advanceAmount,
        'utr_number': utr,
        'booking_status': 'pending',
        'status': 'Pending Verification',
      });

      if (!mounted) return;

      // Show Clean Success Popup Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 28),
              SizedBox(width: 10),
              Text('Booking Submitted!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PNR Number: $pnrNumber', style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 14)),
              const SizedBox(height: 12),
              const Text(
                'Your booking can be accessed anytime from the "My Bookings" section using your mobile number or PNR.\n\nConfirmation will be sent shortly via WhatsApp once your UTR payment is verified by our admin team.',
                style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/my-bookings');
              },
              child: const Text('View My Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Database Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = widget.bookingData['from'] ?? 'Bhopal';
    final to = widget.bookingData['to'] ?? 'Jabalpur';
    final date = widget.bookingData['date'] ?? 'Sat, 19 Sep';
    final time = widget.bookingData['time'] ?? '07:00';
    final carName = widget.bookingData['carName'] ?? 'Sedan';
    final isFullCab = widget.bookingData['isFullCab'] == true;

    final totalAmount = int.tryParse(widget.bookingData['totalAmount']?.toString() ?? '1498') ?? 1498;
    final advanceAmount = int.tryParse(widget.bookingData['advanceAmount']?.toString() ?? '749') ?? 749;
    final balanceToDriver = totalAmount - advanceAmount;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Passenger Details & Payment',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text('$from → $to • $date • $time',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Summary Mini Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isFullCab ? 'Full Cab: $carName' : 'Shared Cab: $carName',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Seats: ${_passengers.map((p) => p.seat).join(', ')}',
                            style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                    const Icon(Icons.verified_user, color: primaryColor),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Contact Information
              const Text('Contact Information',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '10-digit mobile number',
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email ID (e.g. user@example.com)',
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Passengers Section (Dynamic per seat)
              Text(
                isFullCab ? 'Primary Passenger Details' : 'Passenger Details (${_passengers.length} seat(s))',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _passengers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final p = _passengers[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E2D9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seat ${p.seat}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryColor)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: p.nameController,
                          decoration: InputDecoration(
                            hintText: 'Full Name',
                            filled: true,
                            fillColor: fieldBg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: p.ageController,
                                keyboardType: TextInputType.number,
                                maxLength: 2,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: 'Age',
                                  filled: true,
                                  fillColor: fieldBg,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: const Text('Male'),
                              selected: p.gender == 'Male',
                              onSelected: (val) => setState(() => p.gender = 'Male'),
                              selectedColor: primaryColor,
                              labelStyle: TextStyle(
                                  color: p.gender == 'Male' ? Colors.white : Colors.black, fontSize: 12),
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('Female'),
                              selected: p.gender == 'Female',
                              onSelected: (val) => setState(() => p.gender = 'Female'),
                              selectedColor: primaryColor,
                              labelStyle: TextStyle(
                                  color: p.gender == 'Female' ? Colors.white : Colors.black, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Fare Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E2D9)),
                ),
                child: Column(
                  children: [
                    _fareRow('Total Fare', '₹$totalAmount'),
                    _fareRow('Advance Now (50%)', '₹$advanceAmount',
                        isBold: true, color: primaryColor),
                    _fareRow('Balance to driver at ride start',
                        '₹$balanceToDriver'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Pay Advance via UPI QR Code
              const Text('Pay Advance via UPI',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E2D9)),
                  ),
                  child: Column(
                    children: [
                      Image.network(
                        'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=upi://pay?pa=rcmitra@upi&am=$advanceAmount',
                        width: 150,
                        height: 150,
                      ),
                      const SizedBox(height: 10),
                      const Text('UPI ID: rcmitra@upi',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Amount to pay: ₹$advanceAmount',
                          style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: _utrController,
                maxLength: 12,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Enter 12-digit UTR / Ref Number',
                  filled: true,
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    activeColor: primaryColor,
                    onChanged: (val) =>
                        setState(() => _acceptTerms = val ?? false),
                  ),
                  const Expanded(
                    child: Text('I agree to the Terms & Conditions',
                        style: TextStyle(fontSize: 12)),
                  )
                ],
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (!_isFormValid() || _isLoading)
                      ? null
                      : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text('Confirm Booking • Pay ₹$advanceAmount Advance',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _fareRow(String label, String val,
      {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(val,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color)),
        ],
      ),
    );
  }
}