import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

class CheckoutPaymentScreen extends StatefulWidget {
  final String routeId;
  final String fromCity;
  final String toCity;
  final String travelDate;
  final String timeSlot;
  final String vehicleType;
  final List<String> selectedSeats;
  final double totalFare;
  final double advanceAmount;

  CheckoutPaymentScreen({
    super.key,
    this.routeId = 'custom_route',
    required this.fromCity,
    required this.toCity,
    required this.travelDate,
    this.timeSlot = '09:00 AM',
    String? vehicleType,
    String? vehicleCategory,
    this.selectedSeats = const ['Custom Booking'],
    double? totalFare,
    double? totalPrice,
    double? advanceAmount,
  })  : vehicleType = vehicleType ?? vehicleCategory ?? 'Sedan',
        totalFare = totalFare ?? totalPrice ?? 0.0,
        // STRICT 50% ADVANCE CALCULATION (No hardcoded minimums)
        advanceAmount = advanceAmount ?? ((totalFare ?? totalPrice ?? 0.0) * 0.5);

  @override
  State<CheckoutPaymentScreen> createState() => _CheckoutPaymentScreenState();
}

class _CheckoutPaymentScreenState extends State<CheckoutPaymentScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _utrController = TextEditingController();

  String _gender = 'Male';
  bool _acceptedTerms = true;
  bool _isSubmitting = false;
  final String _upiId = '9765416086-2@ybl';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  String get _generateUpiUrl {
    final amount = widget.advanceAmount.toStringAsFixed(2);
    final note = Uri.encodeComponent('RCM Advance Booking - ${widget.fromCity} to ${widget.toCity}');
    return 'upi://pay?pa=$_upiId&pn=Rathod%20Cars%20Mitra&am=$amount&cu=INR&tn=$note';
  }

  Future<void> _launchUpiApp(String appScheme) async {
    final upiUrl = _generateUpiUrl;
    Uri uri;

    if (appScheme == 'gpay') {
      uri = Uri.parse(upiUrl.replaceFirst('upi://', 'gpay://upi/'));
    } else if (appScheme == 'phonepe') {
      uri = Uri.parse(upiUrl.replaceFirst('upi://', 'phonepe://'));
    } else if (appScheme == 'paytm') {
      uri = Uri.parse(upiUrl.replaceFirst('upi://', 'paytmmp://'));
    } else {
      uri = Uri.parse(upiUrl);
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(Uri.parse(upiUrl), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open payment app directly. Please scan the QR code or copy the UPI ID.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _copyUpiId() {
    Clipboard.setData(ClipboardData(text: _upiId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UPI ID copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openPrivacyPolicyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Privacy Policy & Terms of Service',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Rathod Cars Mitra (RCM) Terms & Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryOrange)),
                    SizedBox(height: 12),
                    Text(
                      '1. Passenger Data Collection:\n'
                      'We collect passenger information including full name, mobile number, age, and gender solely for ride allotment, driver allocation, safety verification, and emergency contacts.\n\n'
                      '2. Advance Payment & Verification (50%):\n'
                      'A mandatory 50% advance deposit is required to reserve cab seats. Your 12-digit UPI UTR reference number is recorded in our Supabase database to enable admin verification.\n\n'
                      '3. Balance Payment Terms:\n'
                      'The remaining balance amount must be settled directly with the assigned vehicle driver prior to boarding or upon reaching the journey destination.\n\n'
                      '4. Cancellation & Refund Policy:\n'
                      '• Cancellations made 12+ hours before departure: 80% refund of advance deposit.\n'
                      '• Cancellations within 12 hours of departure: Advance deposit is non-refundable.\n\n'
                      '5. Safety & Luggage Policy:\n'
                      'Passengers must respect luggage limits per seat class. RCM reserves the right to cancel bookings if misleading passenger counts or illegal goods are identified.\n\n'
                      '6. Data Security:\n'
                      'Your personal details are stored securely under encryption and are never sold or shared with external advertising partners.',
                      style: TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('I Understand & Agree', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Privacy Policy and Terms of Service to proceed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final age = _ageController.text.trim();
    final utr = _utrController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final pnrNumber = 'RC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final balance = widget.totalFare - widget.advanceAmount;

      await _supabase.from('bookings').insert({
        'pnr_number': pnrNumber,
        'passenger_name': name,
        'passenger_phone': phone,
        'passenger_email': email.isNotEmpty ? email : null,
        'passenger_age': int.tryParse(age) ?? 0,
        'passenger_gender': _gender,
        'from_location': widget.fromCity,
        'to_location': widget.toCity,
        'travel_date': widget.travelDate,
        'time_slot': widget.timeSlot,
        'vehicle_type': widget.vehicleType,
        'selected_seats': widget.selectedSeats,
        'total_fare': widget.totalFare,
        'advance_amount': widget.advanceAmount,
        'balance_amount': balance,
        'utr_number': utr,
        'payment_status': 'pending_verification',
        'booking_status': 'pending',
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 54),
              SizedBox(height: 12),
              Text(
                'Booking Submitted!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PNR Ref: $pnrNumber',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryOrange),
              ),
              const SizedBox(height: 8),
              Text(
                'Your advance payment of ₹${widget.advanceAmount.toStringAsFixed(0)} (50%) with UTR $utr is submitted for verification.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Balance Due at Boarding: ₹${balance.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Go to Home / My Bookings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double balance = widget.totalFare - widget.advanceAmount;

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Checkout & Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ride Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.fromCity} ➔ ${widget.toCity}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.vehicleType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryOrange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _infoRow('Date & Time', '${widget.travelDate} (${widget.timeSlot})'),
                        _infoRow('Selected Seats', widget.selectedSeats.join(', ')),
                        _infoRow('Total Fare', '₹${widget.totalFare.toStringAsFixed(0)}'),
                        _infoRow('Advance Payable (50%)', '₹${widget.advanceAmount.toStringAsFixed(0)}', isHighlight: true),
                        _infoRow('Balance at Boarding', '₹${balance.toStringAsFixed(0)}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Passenger Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nameController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Please enter passenger full name' : null,
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'Enter full name',
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter mobile number';
                      if (val.trim().length != 10) return 'Must be a 10-digit mobile number';
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: '10-Digit Mobile Number *',
                      hintText: 'Enter 10-digit mobile number',
                      prefixIcon: const Icon(Icons.phone_android_outlined),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email ID (Optional)',
                      hintText: 'e.g., name@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Age Input
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter age';
                            if (int.tryParse(val.trim()) == null) return 'Invalid';
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Age *',
                            hintText: 'e.g., 25',
                            prefixIcon: const Icon(Icons.cake_outlined),
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Gender Selection
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Gender *', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: ['Male', 'Female', 'Others'].map((genderOption) {
                                  final isSelected = _gender == genderOption;
                                  return GestureDetector(
                                    onTap: () => setState(() => _gender = genderOption),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primaryOrange : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        genderOption,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  const Text('Pay Advance Deposit (50%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Pay using any UPI App or Scan QR code below', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _upiAppButton('GPay', Colors.blue.shade700, () => _launchUpiApp('gpay')),
                      const SizedBox(width: 8),
                      _upiAppButton('PhonePe', Colors.purple.shade700, () => _launchUpiApp('phonepe')),
                      const SizedBox(width: 8),
                      _upiAppButton('Paytm', Colors.lightBlue.shade800, () => _launchUpiApp('paytm')),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Advance Amount (50%): ₹${widget.advanceAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryOrange),
                        ),
                        const SizedBox(height: 14),
                        QrImageView(
                          data: _generateUpiUrl,
                          version: QrVersions.auto,
                          size: 190.0,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('UPI ID: $_upiId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18, color: AppColors.primaryOrange),
                              onPressed: _copyUpiId,
                              tooltip: 'Copy UPI ID',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Verify Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _utrController,
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Please enter 12-digit UTR number';
                      if (val.trim().length < 8) return 'Enter a valid UTR / Ref reference number';
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: '12-Digit UTR / UPI Transaction Ref Number *',
                      hintText: 'e.g., 428191919282',
                      prefixIcon: const Icon(Icons.receipt_long_outlined),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Modal-Linked Privacy Policy Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        activeColor: AppColors.primaryOrange,
                        onChanged: (val) {
                          if (val != null) setState(() => _acceptedTerms = val);
                        },
                      ),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('I agree to the ', style: TextStyle(fontSize: 12, color: Colors.black87)),
                            GestureDetector(
                              onTap: _openPrivacyPolicyModal,
                              child: const Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryOrange,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Text(' & Ride Terms', style: TextStyle(fontSize: 12, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting ? null : _submitBooking,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Confirm & Submit Booking',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isHighlight ? AppColors.primaryOrange : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _upiAppButton(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }
}