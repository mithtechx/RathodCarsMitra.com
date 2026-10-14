import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import 'seat_selection_screen.dart';

class CabSelectionScreen extends StatefulWidget {
  final String routeId;
  final String fromCity;
  final String toCity;
  final String travelDate;
  final String timeSlot;

  const CabSelectionScreen({
    super.key,
    this.routeId = 'buldhana-pune',
    this.fromCity = 'Buldhana',
    this.toCity = 'Pune',
    this.travelDate = '2026-10-06',
    this.timeSlot = '09:00 AM',
  });

  @override
  State<CabSelectionScreen> createState() => _CabSelectionScreenState();
}

class _CabSelectionScreenState extends State<CabSelectionScreen> {
  final _supabase = Supabase.instance.client;
  final String _selectedVehicle = 'Sedan';
  late String _currentTravelDate;

  bool _isLoading = true;
  double _farePerSeat = 600.0; // Default fallback

  @override
  void initState() {
    super.initState();
    _currentTravelDate = widget.travelDate;
    _fetchRouteFare();
  }

  Future<void> _fetchRouteFare() async {
    setState(() => _isLoading = true);
    try {
      // Query Supabase route_prices table matching from_city and to_city
      final response = await _supabase
          .from('route_prices')
          .select()
          .ilike('from_city', widget.fromCity.trim())
          .ilike('to_city', widget.toCity.trim())
          .maybeSingle();

      if (response != null && response['fare'] != null) {
        setState(() {
          _farePerSeat = double.tryParse(response['fare'].toString()) ?? 600.0;
          _isLoading = false;
        });
      } else {
        // Fallback check reverse or default
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error fetching route fare: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickNewDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_currentTravelDate) ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _currentTravelDate =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final advancePerSeat = _farePerSeat / 2; // Auto 50% advance calculation

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Vehicle Class',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${widget.fromCity} ➔ ${widget.toCity}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interactive Travel Date Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: AppColors.primaryOrange, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Travel Date: $_currentTravelDate (${widget.timeSlot})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _pickNewDate,
                          icon: const Icon(Icons.edit_calendar, size: 16, color: AppColors.primaryOrange),
                          label: const Text(
                            'Change Date',
                            style: TextStyle(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Available Vehicle Options',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryOrange,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOrange.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.directions_car,
                                    color: AppColors.primaryOrange,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Sedan (Dzire / Etios)',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Comfortable AC ride for up to 4 passengers',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            '₹${_farePerSeat.toStringAsFixed(0)} / seat',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryOrange,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '• Advance: ₹${advancePerSeat.toStringAsFixed(0)}',
                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Radio<String>(
                                  value: 'Sedan',
                                  groupValue: 'Sedan',
                                  activeColor: AppColors.primaryOrange,
                                  onChanged: null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Selected Vehicle', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                              Text(
                                'Sedan',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SeatSelectionScreen(
                                    routeId: widget.routeId,
                                    fromCity: widget.fromCity,
                                    toCity: widget.toCity,
                                    travelDate: _currentTravelDate,
                                    timeSlot: widget.timeSlot,
                                    vehicleType: _selectedVehicle,
                                    farePerSeat: _farePerSeat,
                                  ),
                                ),
                              );
                            },
                            child: const Row(
                              children: [
                                Text(
                                  'Select Seats',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                              ],
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
}