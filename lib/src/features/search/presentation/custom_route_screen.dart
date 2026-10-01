import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomRouteScreen extends StatefulWidget {
  const CustomRouteScreen({super.key});

  @override
  State<CustomRouteScreen> createState() => _CustomRouteScreenState();
}

class _CustomRouteScreenState extends State<CustomRouteScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();

  int _days = 1;
  String _acType = 'AC'; // 'AC' or 'Non-AC'
  String _seatType = '5 Seater'; // '5 Seater' or '7 Seater'
  String _selectedDate = 'Mon, 21 Sep';
  String _selectedTime = '06:00';

  bool _isLoadingPricing = true;

  // Dynamic pricing fetched from Supabase table `pricing_config`
  double _ac5SeaterRate = 13.0;
  double _ac7SeaterRate = 22.0;
  double _nonAc5SeaterRate = 14.0;
  double _nonAc7SeaterRate = 18.0;
  double _minKmPerDay = 300.0;

  static const primaryColor = Color(0xFFD95325);
  static const fieldBg = Color(0xFFEBE8DF);

  final List<String> _dates = ['Mon, 21 Sep', 'Tue, 22 Sep', 'Wed, 23 Sep'];
  final List<String> _times = ['04:00', '06:00', '08:00'];

  @override
  void initState() {
    super.initState();
    _fetchPricingConfig();
  }

  // Fetch rates dynamically from Supabase `pricing_config` table[cite: 3]
  Future<void> _fetchPricingConfig() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('pricing_config').select('config_key, config_value');

      if (response != null) {
        for (var row in response) {
          final key = row['config_key']?.toString();
          final val = double.tryParse(row['config_value']?.toString() ?? '0') ?? 0.0;

          setState(() {
            if (key == 'ac_5seater_rate') _ac5SeaterRate = val;
            if (key == 'ac_7seater_rate') _ac7SeaterRate = val;
            if (key == 'nonac_5seater_rate') _nonAc5SeaterRate = val;
            if (key == 'nonac_7seater_rate') _nonAc7SeaterRate = val;
            if (key == 'min_km_per_day') _minKmPerDay = val;
          });
        }
      }
    } catch (e) {
      print('Error fetching pricing config from Supabase: $e');
    } finally {
      setState(() {
        _isLoadingPricing = false;
      });
    }
  }

  double get _enteredDistance {
    return double.tryParse(_distanceController.text) ?? 0.0;
  }

  // Minimum billing rule based on dynamic database value
  double get _billableDistance {
    final minRule = _days * _minKmPerDay;
    return _enteredDistance > minRule ? _enteredDistance : minRule;
  }

  double get _ratePerKm {
    if (_acType == 'AC') {
      return _seatType == '7 Seater' ? _ac7SeaterRate : _ac5SeaterRate;
    } else {
      return _seatType == '7 Seater' ? _nonAc7SeaterRate : _nonAc5SeaterRate;
    }
  }

  double get _totalFare => _billableDistance * _ratePerKm;
  double get _advanceFare => _totalFare * 0.5;
  double get _balanceFare => _totalFare - _advanceFare;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            child: Icon(Icons.arrow_back, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Custom Route Booking',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Anywhere to anywhere',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route & Car Config Card
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
                  _label('Pickup City / Place'),
                  _textField(_pickupController, 'e.g. Bhopal'),
                  const SizedBox(height: 14),

                  _label('Drop City / Place'),
                  _textField(_dropController, 'e.g. Amarkantak'),
                  const SizedBox(height: 14),

                  _label('Approx Distance (km)'),
                  TextField(
                    controller: _distanceController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'e.g. 380',
                      filled: true,
                      fillColor: fieldBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('Number of days'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (_days > 1) setState(() => _days--);
                            },
                          ),
                          Text(
                            '$daysText',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => _days++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _label('Car Preference'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _toggleChip('AC', _acType == 'AC', () => setState(() => _acType = 'AC')),
                      const SizedBox(width: 10),
                      _toggleChip('Non-AC', _acType == 'Non-AC', () => setState(() => _acType = 'Non-AC')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _toggleChip('5 Seater', _seatType == '5 Seater', () => setState(() => _seatType = '5 Seater')),
                      const SizedBox(width: 10),
                      _toggleChip('7 Seater', _seatType == '7 Seater', () => setState(() => _seatType = '7 Seater')),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Trip Date & Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Date & Time Picker Card
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
                  Row(
                    children: _dates.map((d) {
                      final selected = _selectedDate == d;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedDate = d),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected ? primaryColor : fieldBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: selected ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _label('Departure time'),
                  const SizedBox(height: 8),
                  Row(
                    children: _times.map((t) {
                      final selected = _selectedTime == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTime = t),
                          child: Container(
                            width: 70,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? primaryColor : fieldBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Fare Estimate',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isLoadingPricing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Fare Calculation Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E2D9)),
              ),
              child: Column(
                children: [
                  _fareRow('Distance entered', '${_enteredDistance.toStringAsFixed(0)} km'),
                  const SizedBox(height: 8),
                  _fareRow('Minimum billing (${_minKmPerDay.toStringAsFixed(0)} km/day rule)', '${(_days * _minKmPerDay).toStringAsFixed(0)} km'),
                  const SizedBox(height: 8),
                  _fareRow('Billable distance', '${_billableDistance.toStringAsFixed(0)} km'),
                  const SizedBox(height: 8),
                  _fareRow('Rate ($_acType, $_seatType)', '₹${_ratePerKm.toStringAsFixed(0)}/km'),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total fare',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₹${_totalFare.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _fareRow('Advance now (50%)', '₹${_advanceFare.toStringAsFixed(0)}', highlight: true),
                  const SizedBox(height: 4),
                  _fareRow('Balance to driver', '₹${_balanceFare.toStringAsFixed(0)}'),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  context.push(
                    '/passenger-details',
                    extra: {
                      'routeType': 'Custom',
                      'pickup': _pickupController.text.isEmpty ? 'Bhopal' : _pickupController.text,
                      'drop': _dropController.text.isEmpty ? 'Amarkantak' : _dropController.text,
                      'days': _days,
                      'acType': _acType,
                      'seatType': _seatType,
                      'date': _selectedDate,
                      'time': _selectedTime,
                      'distanceApprox': _billableDistance,
                      'totalFare': _totalFare,
                      'advanceFare': _advanceFare,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue to Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String get daysText => '$_days';

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    );
  }

  Widget _textField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: fieldBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _toggleChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : fieldBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _fareRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: highlight ? primaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }
}