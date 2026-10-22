
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../bookings/my_bookings_screen.dart';

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
        advanceAmount =
            advanceAmount ?? ((totalFare ?? totalPrice ?? 0.0) * 0.5);

  @override
  State<CheckoutPaymentScreen> createState() =>
      _CheckoutPaymentScreenState();
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
    final note = Uri.encodeComponent(
      'RCM Advance Booking - ${widget.fromCity} to ${widget.toCity}',
    );

    return 'upi://pay?pa=$_upiId'
        '&pn=Rathod%20Cars%20Mitra'
        '&am=$amount&cu=INR&tn=$note';
  }

  Future<void> _launchUpiApp(String appScheme) async {
    final upiUrl = _generateUpiUrl;
    late final Uri uri;

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
        await launchUrl(
          Uri.parse(upiUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open the payment app. Please scan the QR code '
            'or copy the UPI ID.',
          ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Privacy Policy & Terms of Service',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rathod Cars Mitra (RCM) Terms & Privacy Policy',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Passenger Data Collection:\n'
                      'We collect passenger information including full name, '
                      'mobile number, age, and gender for ride allotment, '
                      'driver allocation, safety verification, and emergency '
                      'contacts.\n\n'
                      '2. Ride Booking & Confirmation Policy:\n'
                      'Placing a booking request does not mean the ride is '
                      'instantly confirmed. Rides are reviewed, accepted, '
                      'and confirmed by the operator before dispatch.\n\n'
                      '3. Advance Payment & Verification (50%):\n'
                      'A 50% advance deposit is required to reserve cab seats. '
                      'Your UPI UTR reference number is recorded for admin '
                      'verification.\n\n'
                      '4. Balance Payment Terms:\n'
                      'The remaining balance is settled directly with the '
                      'assigned vehicle driver according to the booking terms.\n\n'
                      '5. Cancellation, Refund & Charges Policy:\n'
                      'Operator cancellation: a full refund will be issued '
                      'for a paid ride.\n'
                      'Pre-confirmation customer cancellation: a 10% '
                      'cancellation charge may apply.\n'
                      'Post-confirmation customer cancellation: refunds are '
                      'subject to the applicable cancellation policy.\n\n'
                      '6. Safety & Data Security:\n'
                      'Passenger details are used to manage bookings and '
                      'related safety requirements.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'I Understand & Agree',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
          content: Text(
            'Please accept the Privacy Policy and Terms of Service.',
          ),
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
      final pnrNumber =
          'RC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

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

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 54,
              ),
              SizedBox(height: 12),
              Text(
                'Booking Submitted!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PNR Ref: $pnrNumber',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your advance payment of '
                '₹${widget.advanceAmount.toStringAsFixed(0)} '
                'with UTR $utr has been submitted for verification.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
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
                  'Balance Due at Boarding: '
                  '₹${balance.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.orange,
                  ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Close the confirmation dialog first.
                  Navigator.of(dialogContext).pop();

                  // Open My Bookings directly instead of returning
                  // to the first screen in the navigation stack.
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const MyBookingsScreen(),
                    ),
                    (route) => route.isFirst,
                  );
                },
                child: const Text(
                  'Go to My Bookings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.totalFare - widget.advanceAmount;

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Checkout & Payment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
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
                        _infoRow(
                          'Date & Time',
                          '${widget.travelDate} (${widget.timeSlot})',
                        ),
                        _infoRow(
                          'Selected Seats',
                          widget.selectedSeats.join(', '),
                        ),
                        _infoRow(
                          'Total Fare',
                          '₹${widget.totalFare.toStringAsFixed(0)}',
                        ),
                        _infoRow(
                          'Advance Payable (50%)',
                          '₹${widget.advanceAmount.toStringAsFixed(0)}',
                          isHighlight: true,
                        ),
                        _infoRow(
                          'Balance at Boarding',
                          '₹${balance.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Passenger Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Please enter passenger full name'
                            : null,
                    decoration: _inputDecoration(
                      label: 'Full Name *',
                      hint: 'Enter full name',
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      if (phone.isEmpty) {
                        return 'Please enter mobile number';
                      }
                      if (phone.length != 10) {
                        return 'Must be a 10-digit mobile number';
                      }
                      return null;
                    },
                    decoration: _inputDecoration(
                      label: '10-Digit Mobile Number *',
                      hint: 'Enter 10-digit mobile number',
                      icon: Icons.phone_android_outlined,
                    ).copyWith(counterText: ''),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      label: 'Email ID (Optional)',
                      hint: 'e.g., name@example.com',
                      icon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          maxLength: 3,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            final age = int.tryParse(value?.trim() ?? '');
                            if (age == null) return 'Enter valid age';
                            if (age < 1 || age > 120) {
                              return 'Enter age 1–120';
                            }
                            return null;
                          },
                          decoration: _inputDecoration(
                            label: 'Age *',
                            hint: 'e.g., 25',
                            icon: Icons.cake_outlined,
                          ).copyWith(counterText: ''),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gender *',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: ['Male', 'Female', 'Others']
                                    .map((option) {
                                  final selected = _gender == option;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _gender = option);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.primaryOrange
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: selected
                                              ? Colors.white
                                              : Colors.black87,
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
                  const Text(
                    'Pay Advance Deposit (50%)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pay using any UPI app or scan the QR code below.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _upiAppButton(
                        'GPay',
                        Colors.blue.shade700,
                        () => _launchUpiApp('gpay'),
                      ),
                      const SizedBox(width: 8),
                      _upiAppButton(
                        'PhonePe',
                        Colors.purple.shade700,
                        () => _launchUpiApp('phonepe'),
                      ),
                      const SizedBox(width: 8),
                      _upiAppButton(
                        'Paytm',
                        Colors.lightBlue.shade800,
                        () => _launchUpiApp('paytm'),
                      ),
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
                          'Advance Amount (50%): '
                          '₹${widget.advanceAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        const SizedBox(height: 14),
                        QrImageView(
                          data: _generateUpiUrl,
                          version: QrVersions.auto,
                          size: 190,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'UPI ID: $_upiId',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.copy,
                                size: 18,
                                color: AppColors.primaryOrange,
                              ),
                              onPressed: _copyUpiId,
                              tooltip: 'Copy UPI ID',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Verify Payment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _utrController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      final utr = value?.trim() ?? '';
                      if (utr.isEmpty) {
                        return 'Please enter UTR / reference number';
                      }
                      if (utr.length < 8 || utr.length > 20) {
                        return 'Enter a valid UTR / reference number';
                      }
                      return null;
                    },
                    decoration: _inputDecoration(
                      label: 'UTR / UPI Transaction Reference *',
                      hint: 'e.g., 428191919282',
                      icon: Icons.receipt_long_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        activeColor: AppColors.primaryOrange,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _acceptedTerms = value);
                          }
                        },
                      ),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'I agree to the ',
                              style: TextStyle(fontSize: 12),
                            ),
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
                            const Text(
                              ' & Ride Terms',
                              style: TextStyle(fontSize: 12),
                            ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _submitBooking,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Confirm & Submit Booking',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
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

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isHighlight
                    ? AppColors.primaryOrange
                    : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _upiAppButton(
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
