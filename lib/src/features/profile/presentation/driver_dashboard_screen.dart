import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];
  String _selectedTab = 'Available'; // 'Available' or 'My Rides'

  static const primaryColor = Color(0xFFD95325);
  static const fieldBg = Color(0xFFEBE8DF);

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('bookings')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _bookings = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading rides: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateRideStatus(dynamic bookingId, String newStatus) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', bookingId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride status updated to: $newStatus'), backgroundColor: Colors.green),
      );
      _fetchBookings(); // Refresh list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter bookings based on selected tab
    final filteredBookings = _bookings.where((booking) {
      final status = booking['status'] ?? 'Pending Verification';
      if (_selectedTab == 'Available') {
        // Show pending or unassigned leads
        return status == 'Pending Verification' || status == 'Pending';
      } else {
        // Show active or completed rides
        return status == 'In Progress' || status == 'Completed' || status == 'Confirmed';
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryColor),
            onPressed: _fetchBookings,
            tooltip: 'Refresh Rides',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: fieldBg,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedTab = 'Available'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 'Available' ? primaryColor : Colors.white,
                      foregroundColor: _selectedTab == 'Available' ? Colors.white : Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Available Leads'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedTab = 'My Rides'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTab == 'My Rides' ? primaryColor : Colors.white,
                      foregroundColor: _selectedTab == 'My Rides' ? Colors.white : Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Active / History'),
                  ),
                ),
              ],
            ),
          ),

          // Main List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : filteredBookings.isEmpty
                    ? Center(
                        child: Text(
                          _selectedTab == 'Available' 
                              ? 'No available leads right now.' 
                              : 'No active or historical rides found.',
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          final status = booking['status'] ?? 'Pending Verification';
                          
                          // Expanded fallback mapping to pull accurate fields from Supabase
                          final pickup = booking['pickup_location'] ?? booking['source'] ?? booking['from_location'] ?? 'Buldana';
                          final drop = booking['drop_location'] ?? booking['destination'] ?? booking['to_location'] ?? 'Destination';
                          final carType = booking['car_type'] ?? booking['vehicle_type'] ?? booking['vehicle'] ?? 'Sedan';
                          final seats = booking['seats'] ?? booking['seat_count'] ?? booking['passenger_seats'] ?? '1';
                          
                          final fare = booking['fare'] ?? booking['total_fare'] ?? booking['price'] ?? booking['amount'] ?? booking['total_amount'] ?? '0';
                          final utr = booking['utr_number'] ?? booking['utr'] ?? booking['payment_ref'] ?? booking['transaction_id'] ?? 'N/A';
                          final phone = booking['client_phone'] ?? booking['phone'] ?? booking['passenger_phone'] ?? booking['customer_phone'] ?? 'N/A';
                          final bookingId = booking['id'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E2D9)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '$pickup → $drop',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: status == 'Completed' ? Colors.blue.shade50 : status == 'In Progress' ? Colors.green.shade50 : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: status == 'Completed' ? Colors.blue.shade700 : status == 'In Progress' ? Colors.green.shade700 : Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Car: $carType',
                                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    Text('Seats: $seats',
                                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Fare: ₹$fare',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor)),
                                    Text('UTR: $utr',
                                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('Client Phone: $phone',
                                        style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: bookingId != null ? () => _updateRideStatus(bookingId, 'In Progress') : null,
                                      style: OutlinedButton.styleFrom(foregroundColor: primaryColor),
                                      child: const Text('Start Ride', style: TextStyle(fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: bookingId != null ? () => _updateRideStatus(bookingId, 'Completed') : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Complete', style: TextStyle(fontSize: 12)),
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
}