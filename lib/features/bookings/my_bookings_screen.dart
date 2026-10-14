import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_colors.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final supabase = Supabase.instance.client;
  final _phoneController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  RealtimeChannel? _realtimeChannel;

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _phoneController.dispose();
    super.dispose();
  }

  String _cleanPhone(dynamic raw) {
    if (raw == null) return '';
    String digits = raw.toString().replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }
    return digits;
  }

  String _extractValue(Map<String, dynamic> booking, List<String> keys, String fallback) {
    for (var key in keys) {
      if (booking.containsKey(key) && booking[key] != null && booking[key].toString().trim().isNotEmpty) {
        return booking[key].toString();
      }
    }
    if (booking['passenger_details'] != null && booking['passenger_details'] is Map) {
      final jsonDetails = booking['passenger_details'] as Map;
      for (var key in keys) {
        if (jsonDetails.containsKey(key) && jsonDetails[key] != null && jsonDetails[key].toString().trim().isNotEmpty) {
          return jsonDetails[key].toString();
        }
      }
    }
    return fallback;
  }

  Future<void> _searchBookings() async {
    final searchInput = _phoneController.text.trim();
    final cleanDigits = _cleanPhone(searchInput);

    if (searchInput.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await supabase
          .from('bookings')
          .select()
          .order('created_at', ascending: false);

      final allRows = List<Map<String, dynamic>>.from(response);

      final filtered = allRows.where((b) {
        final phone = _cleanPhone(_extractValue(b, ['passenger_phone', 'phone_number', 'phone', 'mobile'], ''));
        final utr = _extractValue(b, ['utr_number', 'utr'], '');
        final pnr = _extractValue(b, ['pnr_number', 'pnr', 'id'], '').toLowerCase();

        return (cleanDigits.isNotEmpty && phone.contains(cleanDigits)) ||
               (utr.isNotEmpty && utr.contains(searchInput)) ||
               (pnr.isNotEmpty && pnr.contains(searchInput.toLowerCase()));
      }).toList();

      setState(() {
        _searchResults = filtered;
        _isLoading = false;
      });

      _subscribeToRealtimeUpdates();
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  void _subscribeToRealtimeUpdates() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = supabase.channel('public:bookings').onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'bookings',
      callback: (payload) {
        _searchBookings();
      },
    ).subscribe();
  }

  String _formatPnr(Map<String, dynamic> booking) {
    final rawPnr = _extractValue(booking, ['pnr_number', 'pnr'], '');
    if (rawPnr.isNotEmpty) return rawPnr;

    final idStr = (booking['id'] ?? '').toString();
    if (idStr.length > 8) {
      return 'RC-2026-${idStr.substring(0, 8).toUpperCase()}';
    }
    return 'RC-2026-$idStr';
  }

  String _getStatusText(Map<String, dynamic> booking) {
    final paymentStatus = _extractValue(booking, ['payment_status'], 'pending_verification').toString().toLowerCase().trim();
    final bookingStatus = _extractValue(booking, ['booking_status', 'status'], 'pending').toString().toLowerCase().trim();

    if (paymentStatus == 'verified' || 
        paymentStatus == 'confirmed' || 
        paymentStatus == 'paid' || 
        paymentStatus == 'approved' ||
        bookingStatus == 'confirmed' || 
        bookingStatus == 'verified' ||
        bookingStatus == 'approved') {
      return 'CONFIRMED';
    } else if (paymentStatus == 'rejected' || bookingStatus == 'cancelled' || bookingStatus == 'rejected') {
      return 'REJECTED';
    }
    return 'VERIFYING PAYMENT';
  }

  Color _getStatusColor(String statusText) {
    switch (statusText) {
      case 'CONFIRMED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'VERIFYING PAYMENT':
      default:
        return AppColors.primaryOrange;
    }
  }

  Future<void> _printPdfTicket(Map<String, dynamic> booking) async {
    final statusText = _getStatusText(booking);
    final seats = (booking['selected_seats'] as List?)?.join(', ') ?? _extractValue(booking, ['seat_number', 'seat'], 'N/A');
    final pnr = _formatPnr(booking);
    final passengerName = _extractValue(booking, ['passenger_name', 'full_name', 'name'], 'N/A');
    final passengerPhone = _extractValue(booking, ['passenger_phone', 'phone_number', 'phone', 'mobile'], 'N/A');
    final fromCity = _extractValue(booking, ['from_location', 'from_city'], 'Buldhana');
    final toCity = _extractValue(booking, ['to_location', 'to_city'], 'Pune');
    final travelDate = _extractValue(booking, ['travel_date'], 'N/A');
    final departureTime = _extractValue(booking, ['time_slot', 'departure_time'], '09:00 AM');
    final vehicleCategory = _extractValue(booking, ['vehicle_type', 'vehicle_category'], 'Sedan');
    final totalFare = _extractValue(booking, ['total_fare', 'total_price'], '0');
    final advancePaid = _extractValue(booking, ['advance_amount', 'advance_paid'], '300');
    final balanceDue = _extractValue(booking, ['balance_amount'], '300');
    final utrNumber = _extractValue(booking, ['utr_number', 'utr'], 'N/A');

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. BRAND HEADER BANNER
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.black,
                    borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(7)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('RATHOD CARS MITRA (RCM)',
                              style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text('Official E-Ticket & Boarding Pass',
                              style: pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: statusText == 'CONFIRMED' ? PdfColors.green700 : PdfColors.orange700,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          statusText,
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. ROUTE & PNR BAR
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  color: PdfColors.grey200,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ROUTE', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 2),
                          pw.Text('$fromCity to $toCity', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('BOOKING REF / PNR', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 2),
                          pw.Text(pnr, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. PASSENGER & TRIP DETAILS GRID
                pw.Padding(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PASSENGER & TRIP INFORMATION', 
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 10),
                      
                      pw.Row(
                        children: [
                          pw.Expanded(child: _buildPdfField('Passenger Name', passengerName)),
                          pw.Expanded(child: _buildPdfField('Mobile Number', passengerPhone)),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _buildPdfField('Travel Date', travelDate)),
                          pw.Expanded(child: _buildPdfField('Departure Time', departureTime)),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _buildPdfField('Vehicle Category', vehicleCategory)),
                          pw.Expanded(child: _buildPdfField('Seat Number(s)', seats)),
                        ],
                      ),

                      pw.SizedBox(height: 20),
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 10),

                      // 4. FARE BREAKDOWN SECTION
                      pw.Text('FARE & PAYMENT DETAILS', 
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                      pw.SizedBox(height: 10),

                      pw.Row(
                        children: [
                          pw.Expanded(child: _buildPdfField('Total Fare', 'Rs. $totalFare')),
                          pw.Expanded(child: _buildPdfField('Advance Paid', 'Rs. $advancePaid')),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        children: [
                          pw.Expanded(child: _buildPdfField('Balance Due at Boarding', 'Rs. $balanceDue', isHighlight: true)),
                          pw.Expanded(child: _buildPdfField('UTR / Ref Number', utrNumber)),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // 5. FOOTER NOTES
                pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.vertical(bottom: pw.Radius.circular(7)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('• Please arrive 10 minutes prior to departure.\n• Carry a valid Govt ID during travel.',
                          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.Text('Support: +91 8261039902',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfField(String label, String value, {bool isHighlight = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(
          fontSize: 12, 
          fontWeight: pw.FontWeight.bold, 
          color: isHighlight ? PdfColors.red700 : PdfColors.black,
        )),
      ],
    );
  }

  void _showTicketDetailsModal(BuildContext context, Map<String, dynamic> booking) {
    final statusText = _getStatusText(booking);
    final seats = (booking['selected_seats'] as List?)?.join(', ') ?? _extractValue(booking, ['seat_number', 'seat'], 'N/A');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Rathod Cars Mitra - Boarding Pass', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(statusText).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(statusText),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              _detailRow('PNR / Booking Ref', _formatPnr(booking)),
              _detailRow('Passenger Name', _extractValue(booking, ['passenger_name', 'full_name', 'name'], 'N/A')),
              _detailRow('Mobile Number', _extractValue(booking, ['passenger_phone', 'phone_number', 'phone', 'mobile'], 'N/A')),
              _detailRow('Route', '${_extractValue(booking, ['from_location', 'from_city'], 'Buldhana')} ➔ ${_extractValue(booking, ['to_location', 'to_city'], 'Pune')}'),
              _detailRow('Travel Date', _extractValue(booking, ['travel_date'], 'N/A')),
              _detailRow('Departure Time', _extractValue(booking, ['time_slot', 'departure_time'], '09:00 AM')),
              _detailRow('Seat Number(s)', seats),
              _detailRow('Vehicle Category', _extractValue(booking, ['vehicle_type', 'vehicle_category'], 'Sedan')),
              _detailRow('Total Fare', '₹${_extractValue(booking, ['total_fare', 'total_price'], 'N/A')}'),
              _detailRow('Advance Paid', '₹${_extractValue(booking, ['advance_amount', 'advance_paid'], 'N/A')}'),
              _detailRow('Balance Due', '₹${_extractValue(booking, ['balance_amount'], '0')}'),
              _detailRow('UTR Ref Number', _extractValue(booking, ['utr_number', 'utr'], 'N/A')),
              
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _printPdfTicket(booking),
                      icon: const Icon(Icons.print, color: Colors.black, size: 18),
                      label: const Text('Print / Save Ticket', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: AppColors.bgCream,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Bookings & Ride History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Track tickets & payment status', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _searchBookings,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Track by PNR, Phone or UTR Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.fieldBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.text,
                          onSubmitted: (_) => _searchBookings(),
                          decoration: InputDecoration(
                            hintText: 'Enter phone or PNR number',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _searchBookings,
                      child: const Text('Search Rides', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_hasSearched) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your Recent Rides', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('${_searchResults.length} ticket(s) found', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                      : !_hasSearched
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.confirmation_number_outlined, size: 60, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text('Enter your mobile or PNR number above to find your tickets',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                ],
                              ),
                            )
                          : _searchResults.isEmpty
                              ? Center(
                                  child: Text('No active bookings found.', style: TextStyle(color: AppColors.textMuted)),
                                )
                              : ListView.builder(
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final booking = _searchResults[index];

                                    final fromCity = _extractValue(booking, ['from_location', 'from_city'], 'Buldhana');
                                    final toCity = _extractValue(booking, ['to_location', 'to_city'], 'Pune');
                                    final pnr = _formatPnr(booking);
                                    final passName = _extractValue(booking, ['passenger_name', 'full_name', 'name'], 'Passenger');
                                    final advancePaid = _extractValue(booking, ['advance_amount', 'advance_paid'], '300');
                                    final deptTime = _extractValue(booking, ['time_slot', 'departure_time'], '09:00 AM');
                                    final travelDate = _extractValue(booking, ['travel_date'], '2026-10-04');
                                    final statusText = _getStatusText(booking);
                                    final seats = (booking['selected_seats'] as List?)?.join(', ') ?? _extractValue(booking, ['seat_number', 'seat'], '1A');

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: AppColors.cardWhite,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryOrange,
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              const Icon(Icons.circle, color: Colors.white, size: 10),
                                                              const SizedBox(width: 8),
                                                              Flexible(
                                                                child: Text(
                                                                  fromCity,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Padding(
                                                            padding: const EdgeInsets.only(left: 18.0),
                                                            child: Text(
                                                              'PNR: $pnr',
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(deptTime, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),

                                                Row(
                                                  children: [
                                                    const SizedBox(width: 4),
                                                    Expanded(child: Container(height: 1, color: Colors.white38)),
                                                    const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                                                      child: Icon(Icons.directions_bus, color: Colors.white, size: 18),
                                                    ),
                                                    Expanded(child: Container(height: 1, color: Colors.white38)),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),

                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          const Icon(Icons.circle, color: Colors.white, size: 10),
                                                          const SizedBox(width: 8),
                                                          Flexible(
                                                            child: Text(
                                                              toCity,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text('Advance: ₹$advancePaid', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          Padding(
                                            padding: const EdgeInsets.all(14.0),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('$passName • Seat: $seats', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                        const SizedBox(height: 2),
                                                        Text('Date: $travelDate', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                                      ],
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(statusText).withOpacity(0.12),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        statusText,
                                                        style: TextStyle(
                                                          color: _getStatusColor(statusText),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(height: 20),
                                                InkWell(
                                                  onTap: () => _showTicketDetailsModal(context, booking),
                                                  child: const Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.unfold_more, size: 16, color: Colors.blue),
                                                      SizedBox(width: 4),
                                                      Text('View Ticket Details', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}