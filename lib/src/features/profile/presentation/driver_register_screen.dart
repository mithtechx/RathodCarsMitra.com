import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  static const primaryColor = Color(0xFFD95325);
  static const fieldBg = Color(0xFFEBE8DF);

  int seatingIndex = 0; // 0 for 5 Seater, 1 for 7 Seater
  int acIndex = 0; // 0 for AC, 1 for Non-AC
  bool _isUploading = false;

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _licenseNumCtrl = TextEditingController();
  final _carNumCtrl = TextEditingController();
  final _carNameCtrl = TextEditingController();

  File? _aadhaarFile;
  File? _licenseFile;
  File? _rcFile;
  File? _carPhotoFile;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _licenseNumCtrl.dispose();
    _carNumCtrl.dispose();
    _carNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        if (type == 'aadhaar') _aadhaarFile = File(image.path);
        if (type == 'license') _licenseFile = File(image.path);
        if (type == 'rc') _rcFile = File(image.path);
        if (type == 'car_photo') _carPhotoFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadFileToSupabase(File file, String folder, String carNum) async {
    try {
      final fileExt = file.path.split('.').last.toLowerCase();
      final fileName = '$carNum/${folder}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      await Supabase.instance.client.storage
          .from('driver-documents')
          .upload(fileName, file);
      
      final publicUrl = Supabase.instance.client.storage
          .from('driver-documents')
          .getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload error for $folder: $e');
      return null;
    }
  }

  Future<void> _submitDriverRegistration() async {
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final licenseNum = _licenseNumCtrl.text.trim();
    final carNum = _carNumCtrl.text.trim().toUpperCase();

    if (phone.isEmpty || password.length < 6 || licenseNum.isEmpty || carNum.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill phone, 6+ char password, license number, and car number.')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final supabase = Supabase.instance.client;

      // 1. Upload files if selected
      final aadhaarUrl = _aadhaarFile != null ? await _uploadFileToSupabase(_aadhaarFile!, 'aadhaar', carNum) : null;
      final licenseUrl = _licenseFile != null ? await _uploadFileToSupabase(_licenseFile!, 'license', carNum) : null;
      final rcUrl = _rcFile != null ? await _uploadFileToSupabase(_rcFile!, 'rc', carNum) : null;
      final carPhotoUrl = _carPhotoFile != null ? await _uploadFileToSupabase(_carPhotoFile!, 'car_photo', carNum) : null;

      // 2. Insert record into drivers table including license number and password
      await supabase.from('drivers').insert({
        'name': _fullNameCtrl.text.trim(),
        'phone': phone,
        'whatsapp_number': _whatsappCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': password,
        'license_number': licenseNum,
        'car_number': carNum,
        'car_model': _carNameCtrl.text.trim(),
        'seater_capacity': seatingIndex == 1 ? 7 : 5,
        'is_ac': acIndex == 0,
        'aadhaar_url': aadhaarUrl,
        'license_url': licenseUrl,
        'rc_url': rcUrl,
        'car_photo_url': carPhotoUrl,
        'is_verified': false,
        'status': 'Pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver registration submitted for verification!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildField({required String label, required String hint, TextEditingController? ctrl, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            obscureText: obscure,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: fieldBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocSlot(String title, File? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: file != null ? Colors.green.shade50 : fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: file != null ? Colors.green : Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(file != null ? Icons.check_circle_outlined : Icons.cloud_upload_outlined, 
                 color: file != null ? Colors.green : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(file != null ? '$title\n(Selected)' : title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Driver Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Documents are verified by our team', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(label: 'Full Name (as per Aadhaar)', hint: 'Your full name', ctrl: _fullNameCtrl),
                _buildField(label: 'Phone Number', hint: '10-digit mobile number', ctrl: _phoneCtrl),
                _buildField(label: 'WhatsApp Number', hint: '10-digit WhatsApp number', ctrl: _whatsappCtrl),
                _buildField(label: 'Email ID', hint: 'you@example.com', ctrl: _emailCtrl),
                _buildField(label: 'License Number', hint: 'e.g. MH1220230001234', ctrl: _licenseNumCtrl),
                _buildField(label: 'Password', hint: 'Minimum 6 characters', ctrl: _passwordCtrl, obscure: true),
                _buildField(label: 'Car Number', hint: 'e.g. MP09AB1234', ctrl: _carNumCtrl),
                _buildField(label: 'Car Name', hint: 'e.g. Swift Dzire', ctrl: _carNameCtrl),
                const SizedBox(height: 12),
                const Text('Car Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ToggleButtons(
                  isSelected: [seatingIndex == 0, seatingIndex == 1],
                  onPressed: (i) => setState(() => seatingIndex = i),
                  borderRadius: BorderRadius.circular(20),
                  selectedColor: Colors.white,
                  fillColor: primaryColor,
                  color: Colors.black87,
                  constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
                  children: const [Text('5 Seater'), Text('7 Seater')],
                ),
                const SizedBox(height: 16),
                const Text('Car Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ToggleButtons(
                  isSelected: [acIndex == 0, acIndex == 1],
                  onPressed: (i) => setState(() => acIndex = i),
                  borderRadius: BorderRadius.circular(20),
                  selectedColor: Colors.white,
                  fillColor: primaryColor,
                  color: Colors.black87,
                  constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
                  children: const [Text('AC'), Text('Non-AC')],
                ),
                const SizedBox(height: 24),
                const Text('Document Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildDocSlot('Aadhaar Card', _aadhaarFile, () => _pickImage('aadhaar')),
                    _buildDocSlot('Driving License', _licenseFile, () => _pickImage('license')),
                    _buildDocSlot('Car RC', _rcFile, () => _pickImage('rc')),
                    _buildDocSlot('Car Photo', _carPhotoFile, () => _pickImage('car_photo')),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Clear photos help faster verification. Max 8 MB each.',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isUploading ? null : _submitDriverRegistration,
                    icon: _isUploading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Icon(Icons.person_add),
                    label: Text(_isUploading ? 'Registering...' : 'Register'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}