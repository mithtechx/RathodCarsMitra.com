import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

class DriverDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> driverData;
  const DriverDashboardScreen({super.key, required this.driverData});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  bool _isLoading = true;
  List<Map<String, dynamic>> _assignedRides = [];
  List<Map<String, dynamic>> _ongoingRides = [];
  List<Map<String, dynamic>> _completedRides = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDriverRides();
  }

  Future<void> _fetchDriverRides() async {
    setState(() => _isLoading = true);
    try {
      final driverId = widget.driverData['id']?.toString();
      final driverPhone = widget.driverData['phone_number']?.toString().replaceAll(RegExp(r'\D'), '');
      final driverName = widget.driverData['full_name']?.toString().toLowerCase().trim();

      final response = await _supabase.from('bookings').select();
      final allBookings = List<Map<String, dynamic>>.from(response);

      final driverBookings = allBookings.where((b) {
        final bDriverId = b['driver_id']?.toString();
        final bDriverPhone = b['driver_phone']?.toString().replaceAll(RegExp(r'\D'), '');
        final bDriverName = b['driver_name']?.toString().toLowerCase().trim();

        bool idMatch = (driverId != null && bDriverId == driverId);
        bool phoneMatch = (driverPhone != null && driverPhone.isNotEmpty && bDriverPhone == driverPhone);
        bool nameMatch = (driverName != null && driverName.isNotEmpty && bDriverName == driverName);

        return idMatch || phoneMatch || nameMatch;
      }).toList();

      setState(() {
        _assignedRides = driverBookings.where((b) {
          final status = b['booking_status']?.toString().toLowerCase();
          return status == null || status == 'pending' || status == 'assigned' || status == 'confirmed' || status == '';
        }).toList();
        
        _ongoingRides = driverBookings.where((b) {
          final status = b['booking_status']?.toString().toLowerCase();
          return status == 'accepted' || status == 'dispatched';
        }).toList();
        
        _completedRides = driverBookings.where((b) {
          final status = b['booking_status']?.toString().toLowerCase();
          return status == 'completed';
        }).toList();
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching driver rides: $e');
      setState(() => _isLoading = false);
    }
  }

  // --- WHATSAPP MESSAGES ---

  Future<void> _sendDriverAcceptedWhatsApp(Map<String, dynamic> ride) async {
    final phoneRaw = ride['passenger_phone'] ?? '';
    String cleanPhone = phoneRaw.toString().replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 10) cleanPhone = '91$cleanPhone';

    final passengerName = ride['passenger_name'] ?? 'Valued Passenger';
    final driverName = widget.driverData['full_name'] ?? 'Your Assigned Driver';
    final driverPhone = widget.driverData['phone_number'] ?? 'N/A';
    final vehicleModel = widget.driverData['vehicle_model'] ?? 'Sedan';
    final vehicleNumber = widget.driverData['vehicle_number'] ?? 'N/A';
    final pnr = ride['pnr_number'] ?? 'RC-2026';
    final fromCity = ride['from_location'] ?? 'Buldhana';
    final toCity = ride['to_location'] ?? 'Pune';
    final travelDate = ride['travel_date'] ?? 'N/A';
    final departureTime = ride['time_slot'] ?? '09:00 AM';

    final message = '''🌟 RATHOD CARS MITRA (RCM) - RIDE CONFIRMED & ACCEPTED 🌟

Namaste $passengerName ji! 🙏
Thank you immensely for choosing Rathod Cars Mitra as your trusted travel partner. We are delighted to inform you that your ride assignment has been officially accepted by our verified professional driver!

🟢 STATUS: RIDE CONFIRMED & DRIVER ALLOCATED

📋 YOUR COMPREHENSIVE TRIP SUMMARY:
• PNR / Booking Reference: $pnr
• Route: $fromCity ➔ $toCity
• Travel Date: $travelDate
• Scheduled Departure Time: $departureTime

🚘 ASSIGNED DRIVER & VEHICLE DETAILS:
• Driver Name: $driverName
• Driver Mobile Number: $driverPhone (Tap to call/WhatsApp)
• Vehicle Model: $vehicleModel
• Vehicle Number Plate: $vehicleNumber

📌 IMPORTANT TRAVEL GUIDELINES:
1. Your driver will get in touch with you prior to departure to coordinate your exact pickup spot.
2. Please arrive at the designated pickup location at least 10–15 minutes before departure.
3. Keep a valid Government ID proof handy for verification.

For any immediate assistance, modifications, or support, feel free to contact our 24/7 central helpdesk at +91 8261039902. 

Thank you once again for trusting us with your journey. We look forward to providing you with a remarkably safe, smooth, and comfortable ride! Have a wonderful day ahead! ✨''';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  Future<void> _sendRideDispatchedWhatsApp(Map<String, dynamic> ride) async {
    final phoneRaw = ride['passenger_phone'] ?? '';
    String cleanPhone = phoneRaw.toString().replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 10) cleanPhone = '91$cleanPhone';

    final passengerName = ride['passenger_name'] ?? 'Valued Passenger';
    final driverName = widget.driverData['full_name'] ?? 'Driver';
    final driverPhone = widget.driverData['phone_number'] ?? 'N/A';
    final vehicleNumber = widget.driverData['vehicle_number'] ?? 'N/A';
    final pnr = ride['pnr_number'] ?? 'RC-2026';
    final fromCity = ride['from_location'] ?? 'Buldhana';
    final toCity = ride['to_location'] ?? 'Pune';

    final message = '''🚀 RATHOD CARS MITRA (RCM) - RIDE DISPATCHED & STARTED 🚀

Namaste $passengerName ji! 🙏
We are writing to let you know that your trip from $fromCity to $toCity (PNR: $pnr) has officially been dispatched and is now underway! Your verified driver is on the road with you, ensuring a seamless journey.

🔵 STATUS: TRIP IN PROGRESS / DISPATCHED

🚘 ON-ROAD VEHICLE & CREW DETAILS:
• Driver Name: $driverName
• Driver Mobile: $driverPhone
• Vehicle Number Plate: $vehicleNumber

📌 MID-TRIP ASSISTANCE & SAFETY:
• Your safety, comfort, and punctuality are our topmost priorities. 
• If you need to communicate anything urgent to your driver or require mid-trip support, you can reach out directly via call or contact our 24/7 central line at +91 8261039902.

Sit back, relax, and enjoy a pleasant, air-conditioned, and comfortable ride with Rathod Cars Mitra. Thank you for traveling with us! 🌟''';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  Future<void> _sendTripCompletedWhatsApp(Map<String, dynamic> ride) async {
    final phoneRaw = ride['passenger_phone'] ?? '';
    String cleanPhone = phoneRaw.toString().replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 10) cleanPhone = '91$cleanPhone';

    final passengerName = ride['passenger_name'] ?? 'Valued Passenger';
    final driverName = widget.driverData['full_name'] ?? 'Driver';
    final pnr = ride['pnr_number'] ?? 'RC-2026';
    final fromCity = ride['from_location'] ?? 'Buldhana';
    final toCity = ride['to_location'] ?? 'Pune';
    final totalFare = ride['total_fare'] ?? '0';
    final advancePaid = ride['advance_amount'] ?? '300';
    
    final totalNum = double.tryParse(totalFare.toString()) ?? 0.0;
    final advanceNum = double.tryParse(advancePaid.toString()) ?? 300.0;
    final balancePaid = (totalNum > 0) ? (totalNum - advanceNum).toStringAsFixed(0) : '300';

    final message = '''🎉 RATHOD CARS MITRA (RCM) - TRIP SUCCESSFULLY COMPLETED 🎉

Namaste $passengerName ji! 🙏
We are thrilled to inform you that your journey from $fromCity to $toCity (PNR: $pnr) has been successfully and safely completed! We hope you had a wonderful traveling experience with our driver, $driverName.

🟢 STATUS: TRIP COMPLETED & SETTLED

💵 FINAL FARE & PAYMENT BREAKDOWN:
• Total Trip Fare: ₹$totalFare
• Advance Paid Online: ₹$advancePaid
• Balance Paid to Driver: ₹$balancePaid 
✅ PAYMENT STATUS: FULLY SETTLED

⭐ VALUED FEEDBACK & FUTURE TRAVEL:
At Rathod Cars Mitra, customer satisfaction is everything to us. If you have any feedback or suggestions regarding your ride, or if you would like to book your return journey or future trips with us, please feel free to reach out anytime at +91 8261039902 or visit our platform.

Thank you once again for choosing Rathod Cars Mitra as your travel companion. We would love to help you with your future travels as well. Wishing you a fantastic day ahead and hoping to serve you very soon! 🌟🚗''';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  Future<void> _updateRideStatus(Map<String, dynamic> ride, String newStatus) async {
    try {
      final bookingId = ride['id'].toString();
      await _supabase.from('bookings').update({
        'booking_status': newStatus,
      }).eq('id', bookingId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride status updated to: $newStatus'), backgroundColor: Colors.green),
      );

      if (newStatus == 'accepted') {
        await _sendDriverAcceptedWhatsApp(ride);
      } else if (newStatus == 'dispatched') {
        await _sendRideDispatchedWhatsApp(ride);
      } else if (newStatus == 'completed') {
        await _sendTripCompletedWhatsApp(ride);
      }

      _fetchDriverRides();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectRideAssignment(String bookingId) async {
    try {
      await _supabase.from('bookings').update({
        'driver_id': null,
        'driver_name': null,
        'driver_phone': null,
        'vehicle_number': null,
        'booking_status': 'rejected_by_driver',
      }).eq('id', bookingId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride assignment rejected.'), backgroundColor: Colors.orange),
      );
      _fetchDriverRides();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting ride: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverName = widget.driverData['full_name'] ?? 'Driver';
    final vehicleModel = widget.driverData['vehicle_model'] ?? 'Vehicle';
    final vehicleNumber = widget.driverData['vehicle_number'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Driver Panel: $driverName', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchDriverRides,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryOrange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'New Assigned'),
            Tab(text: 'Ongoing Trips'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primaryOrange,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('Vehicle: $vehicleModel ($vehicleNumber)', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRidesList(_assignedRides, isAssignedTab: true),
                      _buildRidesList(_ongoingRides, isOngoingTab: true),
                      _buildRidesList(_completedRides, isCompletedTab: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRidesList(List<Map<String, dynamic>> rides, {bool isAssignedTab = false, bool isOngoingTab = false, bool isCompletedTab = false}) {
    if (rides.isEmpty) {
      return const Center(
        child: Text('No rides found in this category.', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 13)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        final status = ride['booking_status'] ?? 'assigned';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PNR: ${ride['pnr_number']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryOrange)),
                  Text('₹${ride['total_fare'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 6),
              Text('${ride['from_location']} ➔ ${ride['to_location']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text('Travel Date: ${ride['travel_date']} (${ride['time_slot'] ?? '09:00 AM'})', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Text('Passenger: ${ride['passenger_name'] ?? 'N/A'} (${ride['passenger_phone'] ?? 'N/A'})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const Divider(height: 20),

              if (isAssignedTab)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                      onPressed: () => _rejectRideAssignment(ride['id']),
                      child: const Text('Reject Ride'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => _updateRideStatus(ride, 'accepted'),
                      child: const Text('Approve Ride', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),

              if (isOngoingTab)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status: ${status.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12)),
                    Row(
                      children: [
                        if (status == 'accepted' || status == 'confirmed' || status == 'pending' || status == 'assigned')
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            onPressed: () => _updateRideStatus(ride, 'dispatched'),
                            child: const Text('Dispatch (Pickup Done)', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        if (status == 'dispatched')
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: () => _updateRideStatus(ride, 'completed'),
                            child: const Text('Complete Ride', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                      ],
                    ),
                  ],
                ),

              if (isCompletedTab)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Trip Finished Successfully', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('Paid: ₹${ride['total_fare']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}