import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isClientRegisterMode = true;
  bool _isLoading = false;
  
  final _clientNameController = TextEditingController();
  final _clientPhoneController = TextEditingController();
  final _clientPasswordController = TextEditingController();

  static const primaryColor = Color(0xFFD95325);
  static const fieldBg = Color(0xFFEBE8DF);

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleClientAuth() async {
    final phone = _clientPhoneController.text.trim();
    final password = _clientPasswordController.text.trim();
    final name = _clientNameController.text.trim();

    if (phone.length < 10 || password.length < 4) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      if (isClientRegisterMode) {
        if (name.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter your full name for registration.')),
          );
          setState(() => _isLoading = false);
          return;
        }

        // Direct insert into clients table (Bypassing Supabase Auth)
        await supabase.from('clients').insert({
          'name': name,
          'phone': phone,
          'password': password,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client registered successfully! Please log in.')),
        );
        setState(() => isClientRegisterMode = false); // Switch to login mode
      } else {
        // Direct query against clients table for login
        final response = await supabase
            .from('clients')
            .select()
            .eq('phone', phone)
            .eq('password', password)
            .maybeSingle();

        if (response != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Welcome back, ${response['name']}!')),
          );
          // Navigate or update state as logged in client
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid phone number or password.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDemoAccess() async {
    // Instant guest / demo bypass route or auto-login test
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Instant guest access active!')),
    );
  }

  void _autoFillDemoData() {
    _clientPhoneController.text = '9876543210';
    _clientPasswordController.text = '123456';
    if (isClientRegisterMode) {
      _clientNameController.text = 'Test User';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Client account & driver portal', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isClientRegisterMode ? 'Client Register' : 'Client Login',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ToggleButtons(
                        isSelected: [!isClientRegisterMode, isClientRegisterMode],
                        onPressed: (index) {
                          setState(() {
                            isClientRegisterMode = index == 1;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        constraints: const BoxConstraints(minHeight: 32, minWidth: 60),
                        children: const [Text('Login', style: TextStyle(fontSize: 12)), Text('Register', style: TextStyle(fontSize: 12))],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _autoFillDemoData,
                      icon: const Icon(Icons.flash_on, size: 14, color: primaryColor),
                      label: const Text('Auto-fill Test Data', style: TextStyle(fontSize: 11, color: primaryColor)),
                    ),
                  ),
                  if (isClientRegisterMode) ...[
                    TextField(
                      controller: _clientNameController,
                      decoration: const InputDecoration(labelText: 'Full Name', hintText: 'Your full name', filled: true, fillColor: fieldBg),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _clientPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number', hintText: '10-digit mobile number', filled: true, fillColor: fieldBg),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _clientPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password', hintText: 'Minimum 6 characters', filled: true, fillColor: fieldBg),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleClientAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isClientRegisterMode ? 'Create Account' : 'Login'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bolt, size: 16, color: primaryColor),
                      label: const Text('Instant Guest / Demo Access', style: TextStyle(color: primaryColor)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _handleDemoAccess,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Driver Portal Section
          const Text('Driver Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.drive_eta, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Drive with RC Mitra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 2),
                          Text('Register your car, get verified and start earning', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Driver Login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          context.push('/driver-login');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Register as Driver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          context.push('/profile/driver-register');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Booking Rules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _buildRuleItem('50% advance payment confirms your booking'),
          _buildRuleItem('Bookings close 3 hours before departure'),
          _buildRuleItem('Custom trips: minimum 300 km per day billing'),
          _buildRuleItem('Every payment UTR is verified by our team'),
          _buildRuleItem('Support: +91 9876543210'),
          const SizedBox(height: 24),

          const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '1. 50% advance payment is required to confirm a booking. The balance is payable to the driver at the start of the ride.\n'
              '2. Bookings close 3 hours before departure time.\n'
              '3. Share the correct 12-digit UTR / UPI reference number of your advance payment.\n'
              '4. Admin verifies every payment before confirming the ride and assigning a driver.\n'
              '5. Custom route trips follow the minimum 300 km per day billing rule.\n'
              '6. Please be at the pickup point 15 minutes before departure.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade800))),
        ],
      ),
    );
  }
}