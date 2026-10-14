import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'checkout_payment_screen.dart';

class CustomRouteScreen extends StatefulWidget {
  const CustomRouteScreen({super.key});

  @override
  State<CustomRouteScreen> createState() => _CustomRouteScreenState();
}

class _CustomRouteScreenState extends State<CustomRouteScreen> {
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _distanceController = TextEditingController();

  int _numberOfDays = 1;
  bool _isAC = true;
  String _seater = '5 Seater'; // '5 Seater' or '7 Seater'
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '06:00 AM';

  final List<String> _times = ['04:00 AM', '06:00 AM', '08:00 AM', '10:00 AM', '02:00 PM', '06:00 PM'];

  @override
  Widget build(BuildContext context) {
    // Calculation Rules
    final double enteredDistance = double.tryParse(_distanceController.text.trim()) ?? 0.0;
    final double minBillingDistance = 300.0 * _numberOfDays;
    final double billableDistance = enteredDistance > minBillingDistance ? enteredDistance : minBillingDistance;

    final double ratePerKm = _seater == '5 Seater' ? 12.0 : 16.0;
    final double totalFare = billableDistance * ratePerKm;
    final double advanceAmount = totalFare * 0.5;

    final dateOptions = List.generate(3, (index) => DateTime.now().add(Duration(days: index)));
    final String formattedDateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: AppColors.bgCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Custom Route Booking', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17)),
            Text('Anywhere to anywhere', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup & Drop Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField('Pickup City / Place', _pickupController, 'e.g. Buldhana'),
                      const SizedBox(height: 14),
                      _buildInputField('Drop City / Place', _dropController, 'e.g. Pune'),
                      const SizedBox(height: 14),
                      _buildInputField('Approx Distance (km)', _distanceController, 'e.g. 380', isNumber: true),
                      const SizedBox(height: 16),

                      // Number of days
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Number of days', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryOrange),
                                onPressed: () {
                                  if (_numberOfDays > 1) setState(() => _numberOfDays--);
                                },
                              ),
                              Text('$_numberOfDays', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryOrange),
                                onPressed: () => setState(() => _numberOfDays++),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Car Preference
                      const Text('Car Preference', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('AC'),
                            selected: _isAC,
                            selectedColor: AppColors.primaryOrange,
                            labelStyle: TextStyle(color: _isAC ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                            onSelected: (_) => setState(() => _isAC = true),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Non-AC'),
                            selected: !_isAC,
                            selectedColor: AppColors.primaryOrange,
                            labelStyle: TextStyle(color: !_isAC ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                            onSelected: (_) => setState(() => _isAC = false),
                          ),
                          const SizedBox(width: 14),
                          ChoiceChip(
                            label: const Text('5 Seater'),
                            selected: _seater == '5 Seater',
                            selectedColor: AppColors.primaryOrange,
                            labelStyle: TextStyle(color: _seater == '5 Seater' ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                            onSelected: (_) => setState(() => _seater = '5 Seater'),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('7 Seater'),
                            selected: _seater == '7 Seater',
                            selectedColor: AppColors.primaryOrange,
                            labelStyle: TextStyle(color: _seater == '7 Seater' ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                            onSelected: (_) => setState(() => _seater = '7 Seater'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Trip Date & Time Section
                const Text('Trip Date & Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: dateOptions.map((date) {
                      final isSelected = _selectedDate.day == date.day && _selectedDate.month == date.month;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text('${date.day}/${date.month}'),
                          selected: isSelected,
                          selectedColor: AppColors.primaryOrange,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                          onSelected: (_) => setState(() => _selectedDate = date),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Departure time', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _times.map((t) {
                      final isSel = _selectedTime == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(t),
                          selected: isSel,
                          selectedColor: AppColors.primaryOrange,
                          labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                          onSelected: (_) => setState(() => _selectedTime = t),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Fare Estimate Card
                const Text('Fare Estimate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _estimateRow('Distance entered', '${enteredDistance.toInt()} km'),
                      _estimateRow('Minimum billing ($minBillingDistance km/day rule)', '${minBillingDistance.toInt()} km'),
                      _estimateRow('Billable distance', '${billableDistance.toInt()} km'),
                      _estimateRow('Rate (${_isAC ? 'AC' : 'Non-AC'}, $_seater)', '₹${ratePerKm.toInt()}/km'),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total fare', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('₹${totalFare.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryOrange)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _estimateRow('Advance now (50%)', '₹${advanceAmount.toInt()}'),
                      _estimateRow('Balance to driver', '₹${(totalFare - advanceAmount).toInt()}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Continue to Payment Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      final pickup = _pickupController.text.trim();
                      final drop = _dropController.text.trim();

                      if (pickup.isEmpty || drop.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter pickup and drop locations')),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CheckoutPaymentScreen(
                            fromCity: pickup,
                            toCity: drop,
                            travelDate: formattedDateStr,
                            timeSlot: _selectedTime,
                            vehicleCategory: '$_seater (${_isAC ? 'AC' : 'Non-AC'})',
                            selectedSeats: const ['Full Cab'],
                            totalPrice: totalFare,
                          ),
                        ),
                      );
                    },
                    child: const Text('Continue to Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.fieldBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _estimateRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}