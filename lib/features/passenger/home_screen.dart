
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import 'custom_route_screen.dart';
import 'cab_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  // Search State: placeholders are shown initially.
  String _fromCity = '';
  String _toCity = '';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _pnrController = TextEditingController();

  bool _isLoadingRoutes = true;

  // Original fallback cities retained.
  List<String> _cities = [
    'Buldhana',
    'Chhatrapati Sambhaji Nagar',
    'Pune',
    'Nagpur',
    'Mumbai',
    'Shirdi (Only Round Trip)',
    'Ujjain (Only Round Trip)',
  ];

  // Original fallback routes retained.
  List<Map<String, dynamic>> _configuredRoutes = [
    {
      'from_city': 'Buldhana',
      'to_city': 'Chhatrapati Sambhaji Nagar',
      'fare': 600,
      'fullCab': 2400,
    },
    {
      'from_city': 'Buldhana',
      'to_city': 'Nagpur',
      'fare': 1500,
      'fullCab': 6500,
    },
    {
      'from_city': 'Buldhana',
      'to_city': 'Shirdi (Only Round Trip)',
      'fare': 1500,
      'fullCab': 6000,
    },
    {
      'from_city': 'Buldhana',
      'to_city': 'Mumbai',
      'fare': 2500,
      'fullCab': 10000,
    },
    {
      'from_city': 'Buldhana',
      'to_city': 'Ujjain (Only Round Trip)',
      'fare': 2500,
      'fullCab': 10000,
    },
    {
      'from_city': 'Buldhana',
      'to_city': 'Pune',
      'fare': 1500,
      'fullCab': 6000,
    },
  ];

  // Only hide the city selected in the opposite dropdown.
  List<String> get _sourceOptions =>
      _cities.where((city) => city != _toCity).toList();

  List<String> get _destinationOptions =>
      _cities.where((city) => city != _fromCity).toList();

  @override
  void initState() {
    super.initState();
    _fetchRoutesFromDatabase();
  }

  @override
  void dispose() {
    _pnrController.dispose();
    super.dispose();
  }

  Future<void> _fetchRoutesFromDatabase() async {
    try {
      final response = await _supabase.from('route_prices').select();

      if (response != null && (response as List).isNotEmpty) {
        final dbRoutes = List<Map<String, dynamic>>.from(response);

        final Set<String> uniqueCities = {};
        for (var r in dbRoutes) {
          if (r['from_city'] != null) {
            uniqueCities.add(r['from_city'].toString());
          }
          if (r['to_city'] != null) {
            uniqueCities.add(r['to_city'].toString());
          }
        }

        if (!mounted) return;

        setState(() {
          _configuredRoutes = dbRoutes;

          if (uniqueCities.isNotEmpty) {
            _cities = uniqueCities.toList();

            // Keep placeholders instead of automatically selecting cities.
            _fromCity = '';
            _toCity = '';
          }

          _isLoadingRoutes = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _fromCity = '';
          _toCity = '';
          _isLoadingRoutes = false;
        });
      }
    } catch (e) {
      debugPrint(
        'Error fetching database routes, using preloaded fallbacks: $e',
      );

      if (!mounted) return;
      setState(() {
        _fromCity = '';
        _toCity = '';
        _isLoadingRoutes = false;
      });
    }
  }

  Future<void> _pickFromCalendar(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDateShort(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final dayName = days[dt.weekday - 1];
    return '$dayName, ${dt.day} ${months[dt.month - 1]}';
  }

  Future<void> _trackPNR(BuildContext context) async {
    final pnrInput = _pnrController.text.trim();

    if (pnrInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a PNR or UTR reference number'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryOrange,
        ),
      ),
    );

    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .or('pnr_number.ilike.%$pnrInput%,utr_number.ilike.%$pnrInput%')
          .maybeSingle();

      if (!mounted) return;
      Navigator.pop(context);

      if (response == null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'PNR Not Found',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'No booking found matching "$pnrInput". Please verify your entry.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        final status =
            (response['booking_status'] ?? 'pending').toString().toUpperCase();
        final seats =
            (response['selected_seats'] as List?)?.join(', ') ?? 'N/A';

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Booking Details (${response['pnr_number'] ?? pnrInput})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogRow(
                  'Route',
                  '${response['from_location']} ➔ ${response['to_location']}',
                ),
                _dialogRow('Travel Date', '${response['travel_date']}'),
                _dialogRow(
                  'Time Slot',
                  '${response['time_slot'] ?? '09:00 AM'}',
                ),
                _dialogRow('Seats Selected', seats),
                _dialogRow('Total Fare', '₹${response['total_fare']}'),
                _dialogRow('Advance Paid', '₹${response['advance_amount']}'),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'CONFIRMED'
                            ? Colors.green.withOpacity(0.15)
                            : AppColors.primaryOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: status == 'CONFIRMED'
                              ? Colors.green
                              : AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error tracking ticket: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _selectConfiguredRoute(String from, String to) {
    setState(() {
      if (_cities.contains(from)) _fromCity = from;
      if (_cities.contains(to)) _toCity = to;
    });

    final formattedDateStr =
        '${_selectedDate.year}-'
        '${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CabSelectionScreen(
          fromCity: from,
          toCity: to,
          travelDate: formattedDateStr,
          timeSlot: '09:00 AM',
        ),
      ),
    );
  }

  void _searchCabs(String formattedDateStr) {
    if (_fromCity.isEmpty || _toCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select source and destination.'),
        ),
      );
      return;
    }

    if (_fromCity == _toCity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Source and destination cannot be the same city.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CabSelectionScreen(
          fromCity: _fromCity,
          toCity: _toCity,
          travelDate: formattedDateStr,
          timeSlot: '09:00 AM',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDateStr =
        '${_selectedDate.year}-'
        '${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';

    final dateOptions = List.generate(
      4,
      (index) => DateTime.now().add(Duration(days: index)),
    );

    return Container(
      color: AppColors.bgCream,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // Dark Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Rathod Cars Mitra',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Intercity cab - seat-wise booking',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Book Full Cab or Per Seat - AC & Non-AC',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Find your ride',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Main Booking Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'From',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEDE6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sourceOptions.contains(_fromCity) &&
                                _fromCity.isNotEmpty
                            ? _fromCity
                            : null,
                        hint: const Text('Select source'),
                        isExpanded: true,
                        items: _sourceOptions
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _fromCity = val;

                              if (_toCity == _fromCity) {
                                _toCity = '';
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'To',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEDE6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _destinationOptions.contains(_toCity) &&
                                _toCity.isNotEmpty
                            ? _toCity
                            : null,
                        hint: const Text('Select destination'),
                        isExpanded: true,
                        items: _destinationOptions
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  c,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _toCity = val;

                              if (_fromCity == _toCity) {
                                _fromCity = '';
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Select Date Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Date',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _pickFromCalendar(context),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.calendar_month,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Pick from Calendar',
                              style: TextStyle(
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Date Selector Buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: dateOptions.map((date) {
                        final isSelected =
                            _selectedDate.day == date.day &&
                            _selectedDate.month == date.month;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedDate = date),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryOrange
                                    : const Color(0xFFEFEDE6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _formatDateShort(date),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search Cabs Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => _searchCabs(formattedDateStr),
                      child: const Text(
                        'Search Cabs',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Custom Route Booking Card
            const Text(
              'Custom Route Booking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomRouteScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alt_route,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Anywhere to anywhere',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Per-km rates - pay only for distance travelled',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Track by PNR
            const Text(
              'Track by PNR',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEDE6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _pnrController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your PNR or UTR e.g. RC-2026-...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () => _trackPNR(context),
                    child: const Text(
                      'Track',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Configured Routes (From Admin Database)
            const Text(
              'Configured Routes (Live from Admin)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            Column(
              children: _configuredRoutes.map((route) {
                final from = route['from_city'] ?? '';
                final to = route['to_city'] ?? '';
                final fare = route['fare'] ?? route['price'] ?? 0;
                final fullCab =
                    route['fullCab'] ?? (fare is num ? fare * 4 : 2400);

                return InkWell(
                  onTap: () => _selectConfiguredRoute(
                    from.toString(),
                    to.toString(),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$from ➔ $to',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Seat: ₹$fare | Full Cab: ₹$fullCab',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹$fare',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
