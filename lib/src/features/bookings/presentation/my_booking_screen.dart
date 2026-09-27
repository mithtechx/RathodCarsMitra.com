import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  final TextEditingController _searchController = TextEditingController();
  static const primaryColor = Color(0xFFD95325); // Brand Orange
  static const fieldBg = Color(0xFFEBE8DF);

  bool _isLoading = false;
  List<Map<String, dynamic>> _userBookings = [];
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookings(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a PNR or phone number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _userBookings = [];
    });

    try {
      final response = await Supabase.instance.client
          .from('bookings')
          .select()
          .or('pnr_number.ilike.%$trimmedQuery%,passenger_phone.ilike.%$trimmedQuery%')
          .order('created_at', ascending: false);

      setState(() {
        _userBookings = List<Map<String, dynamic>>.from(response);
        if (_userBookings.isEmpty) {
          _errorMessage = 'No bookings found for: $trimmedQuery';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading rides: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings & Ride History',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Track by PNR or Phone Number',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Enter PNR or Registered Phone',
                      filled: true,
                      fillColor: fieldBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _fetchBookings(_searchController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Search Rides'),
                )
              ],
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
            if (_userBookings.isNotEmpty) ...[
              const Text('Your Recent Rides',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF334155))),
              const SizedBox(height: 12),
              ..._userBookings.map((booking) {
                final travelDate = booking['travel_date'] ?? 'N/A';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipPath(
                    clipper: TicketClipper(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // TOP RED/ORANGE ROUTE SECTION (Matches Screenshot Structure)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            color: primaryColor,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Pickup & Time Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle),
                                      ),
                                      Container(
                                        width: 2,
                                        height: 32,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking['pickup_location'] ?? 'Pickup',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'PNR: ${booking['pnr_number']}',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        '16:30', 
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        travelDate,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Middle Vehicle Line Divider
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                          color: Colors.white.withOpacity(0.5),
                                          thickness: 1),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0),
                                      child: Icon(
                                        Icons.directions_bus,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 16,
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                          color: Colors.white.withOpacity(0.5),
                                          thickness: 1),
                                    ),
                                  ],
                                ),
                              ),
                              // Drop & Time Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking['drop_location'] ?? 'Drop',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        '07:30', 
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Advance: ₹${booking['advance_amount'] ?? 0}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // BOTTOM WHITE SECTION (Passenger Info & Action Button)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Rathod Cars Mitra',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        booking['passenger_name'] ?? 'Passenger Name',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${booking['seats_booked'] ?? 1} SEAT',
                                      style: const TextStyle(
                                        color: Color(0xFF1D4ED8),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14.0),
                                child: Divider(
                                  height: 1,
                                  color: Colors.black12,
                                ),
                              ),
                              Center(
                                child: InkWell(
                                  onTap: () {
                                    // Handle viewing booking details or full ticket popup
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.unfold_more,
                                          size: 16, color: Color(0xFF1D4ED8)),
                                      SizedBox(width: 6),
                                      Text(
                                        'View Ticket Details',
                                        style: TextStyle(
                                          color: Color(0xFF1D4ED8),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: const Icon(Icons.confirmation_number,
                            color: primaryColor, size: 30),
                      ),
                      const SizedBox(height: 12),
                      const Text('See all your bookings in one place',
                          style:
                              TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        'Enter your phone number or PNR above to track all recent rides, view invoices and check statuses.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Custom Ticket Clipper creating side punch-holes precisely at the border transition
class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    double radius = 12.0;

    path.lineTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0.0);
    path.close();

    // Notch cutouts positioned right at the division between top header and bottom body (~148px)
    double notchCenterY = 148.0;

    path.addOval(Rect.fromCircle(center: Offset(0, notchCenterY), radius: radius));
    path.addOval(Rect.fromCircle(center: Offset(size.width, notchCenterY), radius: radius));

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}