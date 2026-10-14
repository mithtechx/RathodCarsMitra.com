import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _carNumberController = TextEditingController();
  final TextEditingController _carNameController = TextEditingController();

  String _carType = '5 Seater';
  String _carCategory = 'AC';

  XFile? _aadhaarImg;
  XFile? _licenseImg;
  XFile? _rcImg;
  XFile? _carImg;

  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _licenseController.dispose();
    _passwordController.dispose();
    _carNumberController.dispose();
    _carNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String docType) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        if (docType == 'aadhaar') _aadhaarImg = image;
        if (docType == 'license') _licenseImg = image;
        if (docType == 'rc') _rcImg = image;
        if (docType == 'car') _carImg = image;
      });
    }
  }

  Future<String?> _uploadFileToBucket(XFile? file, String prefix) async {
    if (file == null) return null;
    final supabase = Supabase.instance.client;
    final bytes = await file.readAsBytes();
    final fileExt = file.name.split('.').last;
    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final path = 'driver_docs/$fileName';

    await supabase.storage.from('driver-documents').uploadBinary(path, bytes);
    return supabase.storage.from('driver-documents').getPublicUrl(path);
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_aadhaarImg == null || _licenseImg == null || _rcImg == null || _carImg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload all 4 document photos.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // 1. Upload Document Photos to Storage Bucket
      final aadhaarUrl = await _uploadFileToBucket(_aadhaarImg, 'aadhaar');
      final licenseUrl = await _uploadFileToBucket(_licenseImg, 'license');
      final rcUrl = await _uploadFileToBucket(_rcImg, 'rc');
      final carUrl = await _uploadFileToBucket(_carImg, 'car');

      // 2. Insert into Supabase table matching standard columns
      await supabase.from('driver_registrations').insert({
        'full_name': _fullNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'whatsapp_number': _whatsappController.text.trim(),
        'email': _emailController.text.trim(),
        'license_number': _licenseController.text.trim(),
        'password': _passwordController.text.trim(),
        'car_number': _carNumberController.text.trim(),
        'car_name': _carNameController.text.trim(),
        'car_type': _carType,
        'car_category': _carCategory,
        'aadhaar_card_url': aadhaarUrl,
        'driving_license_url': licenseUrl,
        'car_rc_url': rcUrl,
        'car_photo_url': carUrl,
        'approval_status': 'pending',
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.hourglass_top, color: AppColors.primaryOrange, size: 28),
              SizedBox(width: 10),
              Text('Registration Submitted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: const Text(
            'Your registration details and document photos have been submitted successfully!\n\nOur operations team will review your credentials and activate your driver account.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Driver Registration', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Documents are verified by our team', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputField('Full Name (as per document)', _fullNameController, 'Your full name'),
              _buildInputField('Phone Number', _phoneController, '10-digit mobile number', isPhone: true),
              _buildInputField('WhatsApp Number', _whatsappController, '10-digit WhatsApp number', isPhone: true),
              _buildInputField('Email ID', _emailController, 'you@example.com'),
              _buildInputField('License Number', _licenseController, 'e.g. MH1220230001234'),
              _buildInputField('Password', _passwordController, 'Minimum 6 characters', isObscure: true),
              _buildInputField('Car Number', _carNumberController, 'e.g. MP09AB1234'),
              _buildInputField('Car Name', _carNameController, 'e.g. Swift Dzire'),

              const SizedBox(height: 12),
              const Text('Car Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildOptionToggle('5 Seater', _carType == '5 Seater', () => setState(() => _carType = '5 Seater')),
                  const SizedBox(width: 8),
                  _buildOptionToggle('7 Seater', _carType == '7 Seater', () => setState(() => _carType = '7 Seater')),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Car Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildOptionToggle('AC', _carCategory == 'AC', () => setState(() => _carCategory = 'AC')),
                  const SizedBox(width: 8),
                  _buildOptionToggle('Non-AC', _carCategory == 'Non-AC', () => setState(() => _carCategory = 'Non-AC')),
                ],
              ),

              const SizedBox(height: 20),
              const Text('Document Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _buildUploadBox('Aadhaar Card', _aadhaarImg, () => _pickImage('aadhaar')),
                  _buildUploadBox('Driving License', _licenseImg, () => _pickImage('license')),
                  _buildUploadBox('Car RC', _rcImg, () => _pickImage('rc')),
                  _buildUploadBox('Car Photo', _carImg, () => _pickImage('car')),
                ],
              ),

              const SizedBox(height: 8),
              const Text('Clear photos help faster verification. Max 8 MB each.', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _submitRegistration,
                  icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                  label: Text(
                    _isLoading ? 'Uploading Documents...' : 'Register',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, {bool isPhone = false, bool isObscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: isObscure,
            keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
            validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionToggle(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryOrange : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primaryOrange : Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadBox(String title, XFile? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: file != null ? AppColors.primaryOrange : Colors.grey.shade300, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              file != null ? Icons.check_circle : Icons.cloud_upload_outlined,
              color: file != null ? AppColors.primaryOrange : AppColors.textMuted,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}