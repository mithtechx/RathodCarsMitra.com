import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../driver/driver_dashboard_screen.dart';
import '../driver/driver_register_screen.dart';

class ProfileHubScreen extends StatefulWidget {
  const ProfileHubScreen({super.key});

  @override
  State<ProfileHubScreen> createState() => _ProfileHubScreenState();
}

class _ProfileHubScreenState extends State<ProfileHubScreen> {
  final _supabase = Supabase.instance.client;

  void _showDriverLoginDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Driver Portal Login',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered mobile number and password.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: 'Mobile Number',
                hintText: 'e.g., 9823000000',
                prefixIcon: const Icon(Icons.phone_android),
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter driver password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
            onPressed: () async {
              final phone = phoneController.text.trim();
              final password = passwordController.text.trim();

              if (phone.length != 10 || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid 10-digit number and password.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(ctx); // Close dialog

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
              );

              try {
                Map<String, dynamic>? driverData;

                // 1. Strict check in active 'drivers' table
                final driverRes = await _supabase
                    .from('drivers')
                    .select()
                    .eq('phone_number', phone)
                    .eq('password', password)
                    .maybeSingle();

                if (driverRes != null) {
                  driverData = driverRes;
                } else {
                  // 2. Strict check in 'driver_registrations' table
                  final regRes = await _supabase
                      .from('driver_registrations')
                      .select()
                      .eq('phone_number', phone)
                      .eq('password', password)
                      .eq('approval_status', 'approved')
                      .maybeSingle();

                  if (regRes != null) {
                    driverData = {
                      'id': regRes['id'],
                      'full_name': regRes['full_name'],
                      'phone_number': regRes['phone_number'],
                      'vehicle_model': regRes['car_name'] ?? 'Sedan',
                      'vehicle_number': regRes['car_number'] ?? 'N/A',
                      'vehicle_type': regRes['car_type'] ?? 'Sedan',
                    };
                  }
                }

                if (!mounted) return;
                Navigator.pop(context); // Close loader

                if (driverData != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DriverDashboardScreen(driverData: driverData!),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid mobile number or incorrect password.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Close loader if active
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Login error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Privacy Policy & Terms of Service',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.90,
          height: MediaQuery.of(context).size.height * 0.75,
          child: SingleChildScrollView(
            child: const Text(
              '''RATHOD CARS MITRA (RCM)
MASTER PRIVACY POLICY, TERMS OF SERVICE & LEGAL DISCLAIMER
Last Updated and Effective Date: October 10, 2026

Welcome to Rathod Cars Mitra (“RCM,” “we,” “our,” or “us”). We respect your privacy, value your trust, and are firmly committed to protecting your personal data and legal rights. 

Please read this combined Master Privacy Policy and Terms of Service ("Agreement") carefully before downloading, installing, or using our mobile application (rc_mitra_mobile), our web platform (rathodcarsmitra.com), or any associated booking and aggregator services (collectively, the “Platform”). By accessing, registering on, or using our Platform, you signify your unreserved agreement to be bound by all terms contained herein. If you do not agree to every clause of this Agreement, you must immediately cease usage of our application and services.

1. NATURE OF SERVICE AND TECHNOLOGY INTERMEDIARY ROLE
- Digital Aggregator Model: RCM operates strictly as an independent digital technology platform, software aggregator, and communications intermediary connecting passengers with independent commercial cab operators and drivers.
- Non-Carrier Status: RCM does not own, lease, maintain, manage, control, or operate motor vehicles of any kind. The physical transportation service is provided entirely and independently by third-party Drivers.
- Independent Contractual Bond: When a ride or seat is booked and confirmed via the Platform, a direct, binding contract for transit services is formed exclusively between the Passenger and the Driver. RCM is never a party to that independent carriage contract.

2. ELIGIBILITY, USER REGISTRATION, AND ACCOUNT INTEGRITY
- Legal Capacity: You must be at least 18 years of age and legally competent to enter into binding contracts under the Indian Contract Act, 1872, to use this Platform. Minors are strictly prohibited from holding accounts or booking rides independently.
- Account Information Accuracy: Users must provide accurate, current, and complete information during registration and booking flows. Providing fictitious, fraudulent, or impersonated data results in immediate account suspension, booking forfeiture, and potential civil/criminal liability.

3. BOOKINGS, PRICING, FARES, AND SYSTEM SYNCHRONIZATION
- Real-Time Database Syncing: Base fares, distance algorithms, seat allocations, and route pricing are synchronized dynamically through RCM's centralized backend database. 
- Display Errors and Database Precedence: In the event of a technical glitch, caching failure, network latency anomaly, or manual input error displaying incorrect pricing, the authentic fare structure recorded inside RCM’s official backend database at the time of booking confirmation shall override all frontend displays.

4. PAYMENTS, ADVANCE DEPOSITS, AND DIGITAL COMPLIANCE (RBI/NPCI)
- Advance Payment Mandate: To secure and queue a booking, Passengers must pay an advance percentage (typically 50%) via digital channels. The remaining balance is payable directly to the Driver at boarding or completion.
- Official Business Merchant Compliance: In compliance with Reserve Bank of India (RBI) and National Payments Corporation of India (NPCI) guidelines, all digital funds are routed exclusively into verified business bank accounts. 
- UTR Verification Protocol: Passengers must execute payments externally via authorized UPI applications and enter the correct 12-digit Unique Transaction Reference (UTR) into the app interface. Bookings are officially confirmed only after RCM’s operations team successfully reconciles the submitted UTR against official business bank records.
- Payment Liability Waiver: RCM is completely indemnified from losses, unconfirmed bookings, or transit delays arising from incorrect UTR inputs, expired UPI sessions, or payments mistakenly directed to unauthorized personal accounts.

5. CANCELLATIONS, REFUNDS, AND FRAUDULENT CHARGEBACKS
- Cancellation Rules: Cancellations executed by Passengers through the app interface are governed by active cancellation rules. System-verified refunds for valid cancellations are processed back to the original funding source within standard banking cycles.
- Anti-Fraud & Chargeback Protection: Initiating false, malicious, or fraudulent chargebacks with banking institutions after a successfully verified ride constitutes legal fraud. RCM reserves the right to blacklist offending users and initiate legal action to recover damages.

6. INDEPENDENT DRIVERS, LEGAL LIABILITIES, AND COMPLIANCE
- Independent Contractor Status: Drivers operate as independent commercial entities and third-party service providers. They are not employees, legal agents, partners, or representatives of RCM.
- Statutory Vehicle Compliance: Drivers bear sole legal responsibility for maintaining valid commercial vehicle registrations, fitness certificates, PUC clearances, state permits, and comprehensive commercial motor insurance.
- Traffic Infractions & Criminal Misconduct: RCM holds zero liability for traffic violations, toll evasions, or motor vehicle law breaches. Furthermore, RCM is not responsible for unlawful behavior or criminal actions by Drivers. RCM will cooperate fully with law enforcement authorities upon lawful request.

7. LIMITATION OF LIABILITY AND ON-ROAD TRANSIT RISKS
- Travel at Own Risk: Passengers acknowledge that road transit involves inherent physical hazards. RCM shall not be held directly liable, legally accountable, or financially responsible for on-road traffic accidents, vehicle breakdowns, collisions, injuries, fatalities, luggage loss, theft, delays, or consequential damages.
- Force Majeure: RCM is excused from performance obligations under this Agreement for causes beyond its reasonable control, including acts of God, extreme weather, government restrictions, internet blackouts, or telecom failures.

8. AUTOMATED COMMUNICATIONS AND WHATSAPP INTEGRATION
- Users explicitly consent to receive transactional alerts, booking confirmations, payment approvals, UTR notices, and driver allocation sheets via SMS, push notifications, and automated WhatsApp messaging integrations (+91 98607 58396).

9. INTELLECTUAL PROPERTY RIGHTS
- All application source code, UI/UX graphic layouts, brand logos, software architecture, text phrasing, trademarks, and domain names (rathodcarsmitra.com and rc_mitra_mobile) are the exclusive intellectual property of RCM.

10. GOVERNING LAW AND JURISDICTION
- Governed by the laws of India. Any dispute arising out of or relating to this Agreement shall be subject to the exclusive jurisdiction of the competent courts located in Maharashtra, India.

11. CONTACT AND GRIEVANCE REDRESSAL DESK
- Phone & WhatsApp Helpline: +91 98607 58396
- Official Email Support: rathodcarsmitra@gmail.com
- Official Platform Portal: rathodcarsmitra.com''',
              style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch contact link.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Profile & Customer Care',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Account Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryOrange,
                  child: Icon(Icons.person, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Rathod Cars Mitra Member',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Seamless Ride-Sharing & Travel Portal',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Text(
                      'RCM Secure Passenger Account',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Partner & Driver Portal',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          // Driver Portal Login
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.drive_eta, color: AppColors.primaryOrange),
            ),
            title: const Text('Driver Portal Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Access assigned duties & passenger manifests', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => _showDriverLoginDialog(context),
          ),
          const SizedBox(height: 8),

          // Driver Registration Link
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_add_alt_1, color: Colors.blue),
            ),
            title: const Text('New Driver Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Register your vehicle & join RCM fleet', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverRegisterScreen()),
              );
            },
          ),

          const SizedBox(height: 24),
          const Text(
            'Customer Care & Support',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          // WhatsApp Support Helpline
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat, color: Colors.green),
            ),
            title: const Text('WhatsApp Helpline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('+91 98607 58396 (Instant Assistance)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
            onTap: () => _launchUrl('https://wa.me/919860758396?text=Hello%20RCM%20Support,%20I%20need%20assistance%20with%20my%20ride.'),
          ),
          const SizedBox(height: 8),

          // Direct Phone Call Support
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phone_in_talk, color: Colors.purple),
            ),
            title: const Text('Customer Care Hotline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Call RCM Support Team', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
            onTap: () => _launchUrl('tel:+919860758396'),
          ),

          const SizedBox(height: 24),
          const Text(
            'Legal & Information',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          // Privacy Policy & Terms Popup Trigger
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.privacy_tip_outlined, color: Colors.black87),
            ),
            title: const Text('Privacy Policy & Ride Terms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('View RCM service terms & safety rules', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => _showPrivacyPolicyDialog(context),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}