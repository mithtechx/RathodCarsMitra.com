
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
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _pnrController = TextEditingController();

  String _fromCity = '';
  String _toCity = '';
  DateTime _selectedDate = DateTime.now();

  bool _isLoadingRoutes = true;
  bool _isTrackingPnr = false;
  String? _routeLoadError;

  // No hardcoded fallback routes.
  // The admin-configured Supabase routes are the source of truth.
  List<String> _cities = [];
  List<Map<String, dynamic>> _configuredRoutes = [];

  // Only cities that are configured as route sources.
  List<String> get _sourceOptions {
    final sources = _configuredRoutes
        .map((route) => _cityValue(route['from_city']))
        .where((city) => city.isNotEmpty)
        .toSet()
        .toList();

    sources.sort();
    return sources;
  }

  // Only destinations configured for the selected source.
  // Reverse routes are NOT automatically assumed to exist.
  List<String> get _destinationOptions {
    if (_fromCity.isEmpty) return [];

    final destinations = _configuredRoutes
        .where(
          (route) => _cityValue(route['from_city']) == _fromCity,
        )
        .map((route) => _cityValue(route['to_city']))
        .where(
          (city) => city.isNotEmpty && city != _fromCity,
        )
        .toSet()
        .toList();

    destinations.sort();
    return destinations;
  }

  String _cityValue(dynamic value) {
    return value?.toString().trim() ?? '';
  }

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

  // Load routes configured by the admin.
  // If loading fails or the table is empty, show no fabricated routes.
  Future<void> _fetchRoutesFromDatabase() async {
    if (mounted) {
      setState(() {
        _isLoadingRoutes = true;
        _routeLoadError = null;
      });
    }

    try {
      final response = await _supabase
          .from('route_prices')
          .select();

      final fetchedRoutes =
          List<Map<String, dynamic>>.from(response);

      final validRoutes = fetchedRoutes.where((route) {
        final from = _cityValue(route['from_city']);
        final to = _cityValue(route['to_city']);

        return from.isNotEmpty &&
            to.isNotEmpty &&
            from != to;
      }).toList();

      final sources = validRoutes
          .map((route) => _cityValue(route['from_city']))
          .where((city) => city.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;

      setState(() {
        _configuredRoutes = validRoutes;
        _cities = sources;

        // Clear old selections when refreshing database routes.
        if (!_cities.contains(_fromCity)) {
          _fromCity = '';
          _toCity = '';
        } else if (!_destinationOptions.contains(_toCity)) {
          _toCity = '';
        }

        _isLoadingRoutes = false;
        _routeLoadError = null;
      });
    } catch (e) {
      debugPrint('Error loading admin routes from Supabase: $e');

      if (!mounted) return;

      setState(() {
        _configuredRoutes = [];
        _cities = [];
        _fromCity = '';
        _toCity = '';
        _isLoadingRoutes = false;
        _routeLoadError =
            'Unable to load configured routes. Please check your connection and retry.';
      });
    }
  }

  String _formatDateForDatabase(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _formatDateShort(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    const days = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];

    return '${days[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]}';
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
        ),
      );
  }

  Future<void> _pickFromCalendar() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _searchCabs() {
    if (_isLoadingRoutes) {
      _showMessage('Please wait while routes are loading.');
      return;
    }

    if (_routeLoadError != null) {
      _showMessage(
        'Routes could not be loaded. Please retry.',
        isError: true,
      );
      return;
    }

    if (_configuredRoutes.isEmpty) {
      _showMessage(
        'No routes have been configured by the admin yet.',
        isError: true,
      );
      return;
    }

    if (_fromCity.isEmpty) {
      _showMessage('Please select a source city.');
      return;
    }

    if (_toCity.isEmpty) {
      _showMessage('Please select a destination city.');
      return;
    }

    // Exact direction match: source -> destination.
    // A reverse route must have its own database row.
    final routeExists = _configuredRoutes.any(
      (route) =>
          _cityValue(route['from_city']) == _fromCity &&
          _cityValue(route['to_city']) == _toCity,
    );

    if (!routeExists) {
      _showMessage(
        'This route is not configured by the admin.',
        isError: true,
      );
      return;
    }

    _openCabSelection(_fromCity, _toCity);
  }

  void _selectConfiguredRoute(String from, String to) {
    final exists = _configuredRoutes.any(
      (route) =>
          _cityValue(route['from_city']) == from &&
          _cityValue(route['to_city']) == to,
    );

    if (!exists) {
      _showMessage(
        'This route is no longer available.',
        isError: true,
      );
      return;
    }

    setState(() {
      _fromCity = from;
      _toCity = to;
    });

    _openCabSelection(from, to);
  }

  void _openCabSelection(String from, String to) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CabSelectionScreen(
          fromCity: from,
          toCity: to,
          travelDate: _formatDateForDatabase(_selectedDate),
          timeSlot: '09:00 AM',
        ),
      ),
    );
  }

  Future<void> _trackPNR() async {
    final reference = _pnrController.text.trim();

    if (reference.isEmpty) {
      _showMessage('Please enter your PNR or UTR reference number.');
      return;
    }

    if (_isTrackingPnr) return;

    setState(() {
      _isTrackingPnr = true;
    });

    try {
      Map<String, dynamic>? booking = await _supabase
          .from('bookings')
          .select()
          .ilike('pnr_number', reference)
          .maybeSingle();

      if (booking == null) {
        booking = await _supabase
            .from('bookings')
            .select()
            .ilike('utr_number', reference)
            .maybeSingle();
      }

      if (!mounted) return;

      if (booking == null) {
        _showBookingNotFound(reference);
      } else {
        _showBookingDetails(booking, reference);
      }
    } catch (e) {
      debugPrint('PNR lookup failed: $e');

      if (mounted) {
        _showMessage(
          'Unable to track your booking. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTrackingPnr = false;
        });
      }
    }
  }

  void _showBookingNotFound(String reference) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Booking Not Found',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'No booking was found for "$reference". '
          'Please check your PNR or UTR and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
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
  }

  void _showBookingDetails(
    Map<String, dynamic> booking,
    String fallbackReference,
  ) {
    final status =
        (booking['booking_status'] ?? 'PENDING')
            .toString()
            .toUpperCase();

    final selectedSeats = booking['selected_seats'];
    final seats = selectedSeats is List
        ? selectedSeats.join(', ')
        : selectedSeats?.toString() ?? 'N/A';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Booking Details '
          '(${booking['pnr_number'] ?? fallbackReference})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogRow(
                'Route',
                '${booking['from_location'] ?? 'N/A'} → '
                    '${booking['to_location'] ?? 'N/A'}',
              ),
              _dialogRow(
                'Travel Date',
                '${booking['travel_date'] ?? 'N/A'}',
              ),
              _dialogRow(
                'Time Slot',
                '${booking['time_slot'] ?? '09:00 AM'}',
              ),
              _dialogRow('Seats Selected', seats),
              _dialogRow(
                'Total Fare',
                '₹${booking['total_fare'] ?? 'N/A'}',
              ),
              _dialogRow(
                'Advance Paid',
                '₹${booking['advance_amount'] ?? 'N/A'}',
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Text(
                    'Status: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
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
                              ? Colors.green.shade700
                              : AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.primaryOrange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
              const Expanded(
                child: Text(
                  'Rathod Cars Mitra',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
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
    );
  }

  Widget _buildCityDropdown({
    required String label,
    required String hint,
    required String currentValue,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue =
        currentValue.isNotEmpty && options.contains(currentValue)
            ? currentValue
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
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
              value: validValue,
              hint: Text(hint),
              isExpanded: true,
              items: options.map((city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(
                    city,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: _isLoadingRoutes || options.isEmpty
                  ? null
                  : onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dateOptions = List.generate(
      4,
      (index) => today.add(Duration(days: index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Select Date',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _pickFromCalendar,
              icon: const Icon(
                Icons.calendar_month,
                size: 17,
                color: AppColors.primaryOrange,
              ),
              label: const Text(
                'Pick Date',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: dateOptions.map((date) {
              final selected = _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryOrange
                          : const Color(0xFFEFEDE6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDateShort(date),
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
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
      ],
    );
  }

  Widget _buildBookingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCityDropdown(
            label: 'From',
            hint: _isLoadingRoutes
                ? 'Loading sources...'
                : _cities.isEmpty
                    ? 'No configured sources'
                    : 'Select source',
            currentValue: _fromCity,
            options: _sourceOptions,
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _fromCity = value;

                // Critical fix: clear destination when source changes.
                _toCity = '';
              });
            },
          ),
          const SizedBox(height: 16),
          _buildCityDropdown(
            label: 'To',
            hint: _fromCity.isEmpty
                ? 'Select source first'
                : _destinationOptions.isEmpty
                    ? 'No configured destinations'
                    : 'Select destination',
            currentValue: _toCity,
            options: _destinationOptions,
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _toCity = value;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildDateSelector(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: _searchCabs,
              child: const Text(
                'Search Cabs',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          if (_routeLoadError != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _fetchRoutesFromDatabase,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload routes'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomRouteCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anywhere to anywhere',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
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
    );
  }

  Widget _buildPnrTracker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextField(
            controller: _pnrController,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _trackPNR(),
            decoration: InputDecoration(
              hintText: 'Enter your PNR or UTR reference',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(
                Icons.confirmation_number_outlined,
              ),
              filled: true,
              fillColor: const Color(0xFFEFEDE6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isTrackingPnr ? null : _trackPNR,
              icon: _isTrackingPnr
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(
                _isTrackingPnr ? 'Tracking...' : 'Track Booking',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguredRoutes() {
    if (_isLoadingRoutes) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryOrange,
          ),
        ),
      );
    }

    if (_routeLoadError != null) {
      return _emptyRoutesMessage(
        _routeLoadError!,
        showRetry: true,
      );
    }

    if (_configuredRoutes.isEmpty) {
      return _emptyRoutesMessage(
        'No routes have been configured by the admin yet.',
      );
    }

    return Column(
      children: _configuredRoutes.map((route) {
        final from = _cityValue(route['from_city']);
        final to = _cityValue(route['to_city']);

        final fareValue = route['fare'] ?? route['price'] ?? 0;
        final fare = fareValue is num
            ? fareValue
            : num.tryParse(fareValue.toString()) ?? 0;

        final fullCabValue =
            route['fullCab'] ?? route['full_cab'] ?? route['full_cab_fare'];

        final fullCab = fullCabValue is num
            ? fullCabValue
            : num.tryParse(fullCabValue?.toString() ?? '') ?? fare * 4;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectConfiguredRoute(from, to),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.route,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$from → $to',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Seat: ₹${fare.toStringAsFixed(0)}'
                        ' | Full Cab: ₹${fullCab.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _emptyRoutesMessage(
    String message, {
    bool showRetry = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          if (showRetry) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _fetchRoutesFromDatabase,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCream,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildHeader(),
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
            _buildBookingCard(),
            const SizedBox(height: 24),
            _sectionTitle('Custom Route Booking'),
            const SizedBox(height: 10),
            _buildCustomRouteCard(),
            const SizedBox(height: 24),
            _sectionTitle('Track by PNR'),
            const SizedBox(height: 10),
            _buildPnrTracker(),
            const SizedBox(height: 24),
            _sectionTitle('Configured Routes'),
            const SizedBox(height: 4),
            const Text(
              'Routes configured in the admin dashboard',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            _buildConfiguredRoutes(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
