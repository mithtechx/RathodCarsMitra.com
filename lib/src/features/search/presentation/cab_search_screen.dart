import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CabSearchScreen extends StatefulWidget {
  const CabSearchScreen({super.key});

  @override
  State<CabSearchScreen> createState() => _CabSearchScreenState();
}

class _CabSearchScreenState extends State<CabSearchScreen> {
  static const primaryColor = Color(0xFFD95325);
  static const fieldBg = Color(0xFFEBE8DF);

  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();
  
  String _selectedCarType = '5 Seater AC';
  bool _isSearching = false;
  List<Map<String, dynamic>> _availableCabs = [];

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchCabs() async {
    final pickup = _pickupCtrl.text.trim();
    final drop = _dropCtrl.text.trim();

    if (pickup.isEmpty || drop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both pickup and drop-off locations.')),
      );
      return;
    }

    setState(() => _isSearching = true);
    try {
      // Query verified drivers matching the car category preference
      final response = await Supabase.instance.client
          .from('drivers')
          .select()
          .eq('is_verified', true);

      setState(() {
        _availableCabs = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching cabs: $e')),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _bookRide(Map<String, dynamic> driver) async {
    try {
      await Supabase.instance.client.from('bookings').insert({
        'pickup_location': _pickupCtrl.text.trim(),
        'drop_location': _dropCtrl.text.trim(),
        'car_type': _selectedCarType,
        'fare': 1200.00, // Example flat rate or dynamic calculation
        'status': 'Confirmed',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ride booked successfully with ${driver['name']}!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Cab', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Inputs Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _pickupCtrl,
                      decoration: InputDecoration(
                        labelText: 'Pickup Location',
                        hintText: 'Enter city or landmark',
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.my_location, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dropCtrl,
                      decoration: InputDecoration(
                        labelText: 'Drop-off Location',
                        hintText: 'Enter destination',
                        filled: true,
                        fillColor: fieldBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        prefixIcon: const Icon(Icons.location_on, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isSearching ? null : _searchCabs,
                        child: _isSearching 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Find Available Cabs', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Available Rides', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Results List
            Expanded(
              child: _availableCabs.isEmpty
                  ? Center(
                      child: Text(
                        _isSearching ? 'Searching nearby drivers...' : 'Enter your route to find cabs.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _availableCabs.length,
                      itemBuilder: (context, index) {
                        final driver = _availableCabs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: primaryColor,
                              child: Icon(Icons.directions_car, color: Colors.white),
                            ),
                            title: Text(driver['car_model'] ?? 'Car', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Driver: ${driver['name']} • ${driver['car_number']}'),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                              onPressed: () => _bookRide(driver),
                              child: const Text('Book'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}