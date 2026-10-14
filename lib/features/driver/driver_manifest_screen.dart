import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

class DriverManifestScreen extends StatefulWidget {
  const DriverManifestScreen({super.key});

  @override
  State<DriverManifestScreen> createState() => _DriverManifestScreenState();
}

class _DriverManifestScreenState extends State<DriverManifestScreen> {
  final _supabase = Supabase.instance.client;

  String _selectedRoute = 'Buldhana ➔ Pune';
  String _selectedTimeSlot = '09:00 AM';
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  List<Map<String, dynamic>> _manifestList = [];

  final List<String> _routes = [
    'Buldhana ➔ Pune',
    'Pune ➔ Buldhana',
    'Chhatrapati Sambhajinagar ➔ Pune',
    'Pune ➔ Chhatrapati Sambhajinagar',
  ];

  final List<String> _timeSlots = ['06:00 AM', '09:00 AM', '02:00 PM', '09:00 PM'];

  @override
  void initState() {
    super.initState();
    _fetchManifest();
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _fetchManifest() async {
    setState(() => _isLoading = true);

    final routeParts = _selectedRoute.split(' ➔ ');
    final fromLoc = routeParts[0].trim();
    final toLoc = routeParts[1].trim();
    final travelDateStr = _formatDate(_selectedDate);

    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('from_location', fromLoc)
          .eq('to_location', toLoc)
          .eq('travel_date', travelDateStr)
          .eq('time_slot', _selectedTimeSlot)
          .order('created_at', ascending: true);

      setState(() {
        _manifestList = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching driver manifest: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBoardingStatus(String bookingId, bool currentBoarded) async {
    try {
      final newStatus = currentBoarded ? 'confirmed' : 'boarded';
      await _supabase.from('bookings').update({
        'booking_status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      _fetchManifest();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update boarding status: $e')),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalBalanceToCollect = 0;
    int boardedCount = 0;

    for (var b in _manifestList) {
      if (b['booking_status'] == 'boarded') boardedCount++;
      totalBalanceToCollect += (b['balance_amount'] ?? 0).toDouble();
    }

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        title: const Text('Driver Boarding Manifest', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchManifest,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route & Date Selector Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedRoute,
                        decoration: const InputDecoration(
                          labelText: 'Select Route',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _routes
                            .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRoute = val);
                            _fetchManifest();
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
                                );
                                if (picked != null) {
                                  setState(() => _selectedDate = picked);
                                  _fetchManifest();
                                }
                              },
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(_formatDate(_selectedDate), style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedTimeSlot,
                              decoration: const InputDecoration(
                                labelText: 'Slot',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: _timeSlots
                                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedTimeSlot = val);
                                  _fetchManifest();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Manifest Summary Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Boarded: $boardedCount / ${_manifestList.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Total Balance Due: ₹${totalBalanceToCollect.toInt()}',
                        style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Manifest List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                      : _manifestList.isEmpty
                          ? const Center(
                              child: Text('No bookings found for this slot.', style: TextStyle(color: AppColors.textMuted)),
                            )
                          : ListView.builder(
                              itemCount: _manifestList.length,
                              itemBuilder: (context, index) {
                                final booking = _manifestList[index];
                                final isBoarded = booking['booking_status'] == 'boarded';
                                final List seats = booking['selected_seats'] ?? [];
                                final phone = booking['passenger_phone'] ?? '';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: isBoarded ? Colors.green : Colors.transparent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: isBoarded ? Colors.green : AppColors.primaryOrange,
                                              radius: 18,
                                              child: Text(
                                                seats.isNotEmpty ? seats.first.toString() : 'P',
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    booking['passenger_name'] ?? 'Passenger',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  ),
                                                  Text(
                                                    'Seats (${seats.length}): ${seats.join(', ')}',
                                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.phone, color: Colors.green),
                                              onPressed: phone.isNotEmpty ? () => _makePhoneCall(phone) : null,
                                            ),
                                          ],
                                        ),
                                        const Divider(height: 14),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Collect Balance: ₹${booking['balance_amount']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13),
                                            ),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isBoarded ? Colors.grey : Colors.green,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              ),
                                              onPressed: () => _toggleBoardingStatus(booking['id'].toString(), isBoarded),
                                              icon: Icon(
                                                isBoarded ? Icons.check_circle : Icons.directions_run,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                              label: Text(
                                                isBoarded ? 'Boarded' : 'Mark Boarded',
                                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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