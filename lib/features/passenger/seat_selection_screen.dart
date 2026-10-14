import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import 'checkout_payment_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String routeId;
  final String fromCity;
  final String toCity;
  final String travelDate;
  final String timeSlot;
  final String vehicleType;
  final double farePerSeat;

  const SeatSelectionScreen({
    super.key,
    required this.routeId,
    required this.fromCity,
    required this.toCity,
    required this.travelDate,
    required this.timeSlot,
    required this.vehicleType,
    required this.farePerSeat,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final _supabase = Supabase.instance.client;
  final List<String> _selectedSeats = [];
  
  // Example seats layout for Sedan (Front Passenger + 3 Rear seats)
  final List<Map<String, dynamic>> _seatsLayout = [
    {'id': 'FRONT', 'label': 'Front Passenger', 'type': 'passenger'},
    {'id': 'R1', 'label': 'R1 (Rear Left)', 'type': 'passenger'},
    {'id': 'R2', 'label': 'R2 (Rear Mid)', 'type': 'passenger'},
    {'id': 'R3', 'label': 'R3 (Rear Right)', 'type': 'passenger'},
  ];

  Map<String, String> _seatStatuses = {}; // e.g. {'R1': 'booked', 'R2': 'held'}
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExistingBookings();
  }

  Future<void> _fetchExistingBookings() async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('selected_seats, route_id, travel_date, time_slot, booking_status')
          .eq('route_id', widget.routeId)     // Strict filter for specific route
          .eq('travel_date', widget.travelDate) // Strict filter for specific date
          .eq('time_slot', widget.timeSlot);    // Strict filter for specific time slot

      Map<String, String> statuses = {};
      for (var row in response) {
        final seats = row['selected_seats'];
        final status = row['booking_status']?.toString().toLowerCase() ?? 'booked';
        
        if (seats is List) {
          for (var seat in seats) {
            statuses[seat.toString()] = status == 'completed' ? 'booked' : 'held';
          }
        }
      }

      if (mounted) {
        setState(() {
          _seatStatuses = statuses;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching seat statuses: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSeatSelection(String seatId) {
    setState(() {
      if (_selectedSeats.contains(seatId)) {
        // DESELECT: Remove seat if it's already selected by the user
        _selectedSeats.remove(seatId);
      } else {
        // SELECT: Add seat if max limit (4) isn't reached
        if (_selectedSeats.length < 4) {
          _selectedSeats.add(seatId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 4 seats can be selected for a Sedan.'), backgroundColor: Colors.orange),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalFare = _selectedSeats.length * widget.farePerSeat;

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.fromCity} ➔ ${widget.toCity}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              'Date: ${widget.travelDate} (${widget.timeSlot}) • ${widget.vehicleType}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Status Legend Bar
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem(Colors.white, 'Available', Colors.grey),
                        _buildLegendItem(AppColors.primaryOrange, 'Selected', Colors.white),
                        _buildLegendItem(Colors.orange.shade200, 'Held', Colors.black87),
                        _buildLegendItem(Colors.grey.shade400, 'Booked', Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cabin Layout Visualizer Box
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 320,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('FRONT (CABIN)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 90,
                                  height: 65,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.airline_seat_recline_normal, size: 20, color: Colors.grey),
                                      Text('Driver', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                _buildSeatWidget(_seatsLayout[0]), // Front Passenger
                              ],
                            ),
                            const Divider(height: 30, thickness: 2),
                            const Text('REAR SEATS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSeatWidget(_seatsLayout[1]), // R1
                                _buildSeatWidget(_seatsLayout[2]), // R2
                                _buildSeatWidget(_seatsLayout[3]), // R3
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Checkout Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -4))],
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${_selectedSeats.length} Seat(s) Selected', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              Text(
                                '₹${totalFare.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryOrange),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedSeats.isEmpty ? Colors.grey : AppColors.primaryOrange,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _selectedSeats.isEmpty
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CheckoutPaymentScreen(
                                          routeId: widget.routeId,
                                          fromCity: widget.fromCity,
                                          toCity: widget.toCity,
                                          travelDate: widget.travelDate,
                                          timeSlot: widget.timeSlot,
                                          vehicleType: widget.vehicleType,
                                          selectedSeats: _selectedSeats,
                                          totalFare: totalFare,
                                        ),
                                      ),
                                    );
                                  },
                            child: const Text(
                              'Proceed to Pay',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLegendItem(Color boxColor, String label, Color textColor) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: boxColor,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSeatWidget(Map<String, dynamic> seatInfo) {
    final seatId = seatInfo['id'].toString();
    final status = _seatStatuses[seatId] ?? 'available';
    final isSelected = _selectedSeats.contains(seatId);

    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade400;
    Color fgColor = Colors.black87;

    if (status == 'booked') {
      bgColor = Colors.grey.shade300;
      borderColor = Colors.grey.shade400;
      fgColor = Colors.grey.shade600;
    } else if (status == 'held') {
      bgColor = Colors.orange.shade100;
      borderColor = Colors.orange.shade300;
      fgColor = Colors.orange.shade900;
    } else if (isSelected) {
      bgColor = AppColors.primaryOrange;
      borderColor = AppColors.primaryOrange;
      fgColor = Colors.white;
    }

    return GestureDetector(
      onTap: () {
        if (status == 'booked') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This seat is already booked.'), backgroundColor: Colors.red),
          );
        } else if (status == 'held') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This seat is currently held by another passenger.'), backgroundColor: Colors.orange),
          );
        } else {
          // Toggle selection (Select / Deselect instantly)
          _toggleSeatSelection(seatId);
        }
      },
      child: Container(
        width: 85,
        height: 65,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'held' ? Icons.lock_clock : Icons.chair,
              size: 20,
              color: fgColor,
            ),
            const SizedBox(height: 4),
            Text(
              seatId,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fgColor),
            ),
          ],
        ),
      ),
    );
  }
}