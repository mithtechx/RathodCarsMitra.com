import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

class PassengerManifestScreen extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final String travelDate;
  final String driverId;

  const PassengerManifestScreen({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.travelDate,
    required this.driverId,
  });

  @override
  State<PassengerManifestScreen> createState() => _PassengerManifestScreenState();
}

class _PassengerManifestScreenState extends State<PassengerManifestScreen> {
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _manifestBookings = [];
  String _tripStatus = 'assigned';

  @override
  void initState() {
    super.initState();
    _fetchPassengerManifest();
  }

  Future<void> _fetchPassengerManifest() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('driver_id', widget.driverId)
          .eq('from_location', widget.fromCity)
          .eq('to_location', widget.toCity)
          .eq('travel_date', widget.travelDate)
          .neq('booking_status', 'cancelled')
          .order('created_at', ascending: true);

      if (response.isNotEmpty) {
        _tripStatus = response[0]['trip_status'] ?? 'assigned';
      }

      setState(() {
        _manifestBookings = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching passenger manifest: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _callPassenger(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error launching dialer: $e');
    }
  }

  Future<void> _collectBalance(String bookingId, double balanceAmount) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Collect Balance Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Confirm collection of remaining balance ₹${balanceAmount.toStringAsFixed(0)} from passenger?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _supabase
                    .from('bookings')
                    .update({'payment_status': 'fully_paid', 'balance_amount': 0.0})
                    .eq('id', bookingId);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Balance collected & payment marked as Fully Paid!'), backgroundColor: Colors.green),
                );
                _fetchPassengerManifest();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating payment: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Mark as Paid', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTripStatus(String newStatus) async {
    try {
      await _supabase
          .from('bookings')
          .update({'trip_status': newStatus})
          .eq('driver_id', widget.driverId)
          .eq('travel_date', widget.travelDate)
          .eq('from_location', widget.fromCity)
          .eq('to_location', widget.toCity);

      setState(() => _tripStatus = newStatus);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Trip status updated to: $newStatus'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating trip status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPassengers = 0;
    double totalBalanceDue = 0.0;

    for (var b in _manifestBookings) {
      totalPassengers += ((b['selected_seats'] as List?)?.length ?? 1);
      totalBalanceDue += (b['balance_amount'] as num?)?.toDouble() ?? 0.0;
    }

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Passenger Manifest', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${widget.fromCity} ➔ ${widget.toCity} (${widget.travelDate})', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryBadge('Total Seats', '$totalPassengers Booked', Icons.people_outline),
                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                      _summaryBadge('Balance Due', '₹${totalBalanceDue.toStringAsFixed(0)}', Icons.currency_rupee),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Trip Status:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(8),
                        selectedColor: Colors.white,
                        fillColor: AppColors.primaryOrange,
                        color: Colors.black87,
                        constraints: const BoxConstraints(minHeight: 32, minWidth: 90),
                        isSelected: [
                          _tripStatus == 'assigned',
                          _tripStatus == 'in_transit',
                          _tripStatus == 'completed',
                        ],
                        onPressed: (index) {
                          if (index == 0) _updateTripStatus('assigned');
                          if (index == 1) _updateTripStatus('in_transit');
                          if (index == 2) _updateTripStatus('completed');
                        },
                        children: const [
                          Text('Assigned', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('In Transit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _manifestBookings.isEmpty
                      ? const Center(child: Text('No passenger bookings found for this route.', style: TextStyle(color: AppColors.textMuted)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _manifestBookings.length,
                          itemBuilder: (context, index) {
                            final booking = _manifestBookings[index];
                            final seats = (booking['selected_seats'] as List?)?.join(', ') ?? 'N/A';
                            final balance = (booking['balance_amount'] as num?)?.toDouble() ?? 0.0;
                            final isPaid = booking['payment_status'] == 'fully_paid';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        booking['passenger_name'] ?? 'Passenger',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.orange.shade200),
                                        ),
                                        child: Text(
                                          'Seat(s): $seats',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primaryOrange),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'PNR: ${booking['pnr_number']} • Age/Gender: ${booking['passenger_age'] ?? 'N/A'} yrs (${booking['passenger_gender'] ?? 'N/A'})',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.black87,
                                          side: BorderSide(color: Colors.grey.shade300),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => _callPassenger(booking['passenger_phone'] ?? ''),
                                        icon: const Icon(Icons.phone, size: 16, color: Colors.green),
                                        label: Text(booking['passenger_phone'] ?? '', style: const TextStyle(fontSize: 12)),
                                      ),
                                      isPaid
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.green.shade300),
                                              ),
                                              child: const Text('✔ Fully Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                                            )
                                          : ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primaryOrange,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              onPressed: () => _collectBalance(booking['id'], balance),
                                              child: Text('Collect ₹${balance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                            ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _summaryBadge(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          ],
        ),
      ],
    );
  }
}