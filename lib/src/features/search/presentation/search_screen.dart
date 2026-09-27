import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String? _selectedFrom;
  String? _selectedTo;
  DateTime _selectedDateTime = DateTime.now();

  final TextEditingController _pnrController = TextEditingController();

  static const primaryColor = Color(0xFFD95325);
  static const fieldBg = Color(0xFFEBE8DF);

  List<Map<String, dynamic>> _allRoutes = [];
  bool _isLoadingRoutes = true;

  @override
  void initState() {
    super.initState();
    _fetchRoutesFromDatabase();
  }

  Future<void> _fetchRoutesFromDatabase() async {
    try {
      final response = await Supabase.instance.client.from('routes_pricing').select();
      final routes = List<Map<String, dynamic>>.from(response);
      
      setState(() {
        _allRoutes = routes;
        _isLoadingRoutes = false;
        
        if (_allRoutes.isNotEmpty) {
          _selectedFrom = _allRoutes.first['pickup_city']?.toString().trim();
          final availableDestinations = getDestinationsForSource(_selectedFrom!);
          if (availableDestinations.isNotEmpty) {
            _selectedTo = availableDestinations.first;
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching routes from Supabase: $e');
      setState(() => _isLoadingRoutes = false);
    }
  }

  List<String> getUniqueSources() {
    return _allRoutes
        .map((r) => r['pickup_city']?.toString().trim() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> getDestinationsForSource(String source) {
    return _allRoutes
        .where((r) => r['pickup_city']?.toString().trim() == source)
        .map((r) => r['drop_city']?.toString().trim() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  Future<void> _pickDateFromCalendar() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = picked;
      });
    }
  }

  @override
  void dispose() {
    _pnrController.dispose();
    super.dispose();
  }

  void _searchCabs() {
    if (_selectedFrom == null || _selectedTo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both From and To cities')),
      );
      return;
    }

    final matchedRoute = _allRoutes.firstWhere(
      (r) => 
          r['pickup_city']?.toString().trim() == _selectedFrom && 
          r['drop_city']?.toString().trim() == _selectedTo,
      orElse: () => {},
    );

    final seatPrice = matchedRoute['seat_price'] ?? 0;
    final fullCabPrice = matchedRoute['full_cab_price'] ?? 0;

    context.push('/cab-list', extra: {
      'from': _selectedFrom,
      'to': _selectedTo,
      'date': _formatDate(_selectedDateTime),
      'seat_price': seatPrice,
      'full_cab_price': fullCabPrice,
    });
  }

  @override
  Widget build(BuildContext context) {
    final sources = getUniqueSources();
    final destinations = _selectedFrom != null ? getDestinationsForSource(_selectedFrom!) : <String>[];

    final List<DateTime> upcomingDays = List.generate(
      30,
      (index) => DateTime.now().add(Duration(days: index)),
    );

    return Scaffold(
      body: SafeArea(
        child: _isLoadingRoutes
            ? const Center(child: CircularProgressIndicator(color: primaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E1E1E), Color(0xFF3A3A3A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: primaryColor,
                                child: const Icon(
                                  Icons.directions_car,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Rathod Cars Mitra',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Intercity cab - seat-wise booking',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor,
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

                    const SizedBox(height: 20),
                    const Text(
                      'Find your ride',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Search Box Form
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E2D9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'From',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: sources.contains(_selectedFrom) ? _selectedFrom : null,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: sources
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedFrom = val;
                                  final newDestinations = getDestinationsForSource(val);
                                  _selectedTo = newDestinations.isNotEmpty ? newDestinations.first : null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          const Text(
                            'To',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: destinations.contains(_selectedTo) ? _selectedTo : null,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: fieldBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: destinations
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedTo = val),
                          ),
                          const SizedBox(height: 16),

                          // Date Selection Header & Calendar Picker Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Select Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _pickDateFromCalendar,
                                icon: const Icon(Icons.calendar_month, size: 16, color: primaryColor),
                                label: const Text(
                                  'Pick from Calendar',
                                  style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Scrollable Horizontal Date Selector Chips
                          SizedBox(
                            height: 44,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: upcomingDays.length,
                              itemBuilder: (context, index) {
                                final date = upcomingDays[index];
                                final isSelected = date.year == _selectedDateTime.year &&
                                    date.month == _selectedDateTime.month &&
                                    date.day == _selectedDateTime.day;
                                final dateStr = _formatDate(date);

                                return GestureDetector(
                                  onTap: () => setState(() => _selectedDateTime = date),
                                  child: Container(
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected ? primaryColor : fieldBg,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Search Cabs Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _searchCabs,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Search Cabs',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Custom Route Booking Banner
                    const Text(
                      'Custom Route Booking',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => context.push('/custom-route'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E2D9)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: primaryColor,
                              child: Icon(Icons.route, color: Colors.white),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Anywhere to anywhere',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'Per-km rates - pay only for distance travelled',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Track by PNR Card
                    const Text(
                      'Track by PNR',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E2D9)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _pnrController,
                              decoration: InputDecoration(
                                hintText: 'Enter your PNR e.g. RCMABC123',
                                filled: true,
                                fillColor: fieldBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (_pnrController.text.isNotEmpty) {
                                context.go('/my-bookings');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Track'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Live Admin Routes & Pricing list (Directly redirects to cab-list with chosen date & route)
                    const Text(
                      'Configured Routes (From Admin)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (_allRoutes.isEmpty)
                      const Text('No routes created in Admin Portal yet.', style: TextStyle(color: Colors.grey))
                    else
                      ..._allRoutes.map((routeMap) {
                        final pickup = routeMap['pickup_city']?.toString().trim() ?? '';
                        final drop = routeMap['drop_city']?.toString().trim() ?? '';
                        final seatPrice = routeMap['seat_price'] ?? 0;
                        final fullPrice = routeMap['full_cab_price'] ?? 0;

                        return Card(
                          elevation: 0,
                          color: Colors.white,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE5E2D9)),
                          ),
                          child: ListTile(
                            title: Text(
                              '$pickup → $drop',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text('Seat: ₹$seatPrice | Full Cab: ₹$fullPrice', style: const TextStyle(fontSize: 12)),
                            trailing: Text(
                              '₹$seatPrice',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 14,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedFrom = pickup;
                                final validDestinations = getDestinationsForSource(pickup);
                                if (validDestinations.contains(drop)) {
                                  _selectedTo = drop;
                                } else if (validDestinations.isNotEmpty) {
                                  _selectedTo = validDestinations.first;
                                }
                              });

                              // Directly trigger navigation using the currently selected date & prices
                              context.push('/cab-list', extra: {
                                'from': pickup,
                                'to': drop,
                                'date': _formatDate(_selectedDateTime),
                                'seat_price': seatPrice,
                                'full_cab_price': fullPrice,
                              });
                            },
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}