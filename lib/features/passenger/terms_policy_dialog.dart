import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TermsAndConditionsDialog extends StatelessWidget {
  const TermsAndConditionsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TermsAndConditionsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.cardWhite,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RATHOD CARS MITRA (RCM)',
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'TERMS AND CONDITIONS & PRIVACY POLICY',
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Last Updated and Effective Date: September 27, 2026',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            // Scrollable Content
            const Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Rathod Cars Mitra (“RCM,” “we,” “our,” or “us”).\n\n'
                      'Please read these Terms and Conditions (“Terms” or “Agreement”) carefully before downloading, installing, or using the RCM mobile application (rc_mitra_mobile), web platform (rathodcarsmitra.com), or any associated services. By accessing or using our platform, you signify your agreement to be bound by these Terms. If you do not agree to all of these Terms, we recommend not to use our application or services.\n',
                      style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textDark),
                    ),

                    _PolicySection(
                      title: '1. Nature of Service and Platform Role',
                      body: '• Technology Intermediary: RCM operates strictly as a digital technology platform and booking aggregator that connects individual passengers (“Users” or “Passengers”) with independent commercial cab operators, drivers, and vehicle owners (“Drivers”).\n\n'
                          '• Non-Carrier Status: RCM does not own, lease, manage, or operate motor vehicles. RCM is not a transportation carrier, public utility, or car rental agency. The transportation service itself is provided entirely by independent Drivers.\n\n'
                          '• Contractual Relationship: When a ride is booked and confirmed through the platform, a direct contract for transportation services is formed exclusively between the Passenger and the Driver. RCM is not a party to that independent contract.',
                    ),

                    _PolicySection(
                      title: '2. Eligibility and User Accounts',
                      body: '• Age Requirement: You must be at least 18 years of age and legally competent to enter into contracts under the Indian Contract Act, 1872, to use this platform.\n\n'
                          '• Account Information: Users must provide accurate, current, and complete information during registration and booking, including their legal name, age, gender, and valid mobile number. Providing false information may lead to immediate account termination and legal forfeiture of bookings.',
                    ),

                    _PolicySection(
                      title: '3. Bookings, Fares, and Pricing Policy',
                      body: '• Dynamic and Real-Time Syncing: Base fares, distance calculations, and pricing rules are synchronized dynamically through our centralized database to ensure accurate, up-to-date estimates.\n\n'
                          '• Fare Components: The total fare includes the base travel charge, applicable tolls, state taxes, and night-driving allowances, where specified.\n\n'
                          '• Database Binding: In the event of a technical display error or manual input anomaly, the pricing reflected in RCM’s official backend database at the time of booking confirmation shall prevail.',
                    ),

                    _PolicySection(
                      title: '4. Payments, Advance Deposits, and Dynamic QR Compliance',
                      body: '• Advance Payment Structure: To secure a booking, Passengers are required to pay an advance percentage—typically 50% of the total estimated fare—as displayed in the application. The remaining balance is settled directly with the Driver at the start or completion of the ride.\n\n'
                          '• Dynamic UPI QR and Merchant Compliance: RCM utilizes official business merchant accounts and dynamic UPI QR codes generated or displayed securely within the app workflow. In compliance with Reserve Bank of India (RBI) and National Payments Corporation of India (NPCI) guidelines, all digital collections are channeled strictly into verified corporate or proprietorship business bank accounts to ensure transparency and tax compliance.\n\n'
                          '• Manual UTR Verification Process: Passengers must complete the payment externally through their chosen UPI app and enter the correct 12-digit Unique Transaction Reference (UTR) or reference number into the RCM application before submitting their booking. Bookings are officially validated and marked as confirmed only after RCM’s 24/7 operations and finance team successfully cross-references and reconciles the submitted UTR against incoming business bank statements.\n\n'
                          '• Liability for Payment Errors: RCM shall not be held liable for delayed ride confirmations, lost bookings, or disputes arising from incorrect UTR entries, expired UPI sessions, payments made to unauthorized personal accounts, or bank gateway outages.',
                    ),

                    _PolicySection(
                      title: '5. Cancellations, Refunds, and Dispute Resolution',
                      body: '• Cancellation Terms: Passengers may cancel bookings through the app interface, subject to the cancellation guidelines active at the time of booking. Advance fees for valid, system-verified cancellations or unfulfilled trips will be processed back to the original source account within standard banking cycles.\n\n'
                          '• Chargebacks and Fraudulent Claims: Raising false chargebacks with banking institutions after a completed or successfully verified ride constitutes legal fraud. RCM reserves the right to blacklist Users and initiate legal action to recover losses and damages in such cases.',
                    ),

                    _PolicySection(
                      title: '6. Independent Drivers, Compliance, and Legal Liabilities',
                      body: '• Independent Contractor Status: Drivers registered on the RCM platform operate as independent business owners and third-party contractors. They are not employees, workers, legal agents, or partners of RCM.\n\n'
                          '• Statutory Compliance and Documentation: Drivers are solely responsible for maintaining valid commercial vehicle registration, fitness certificates, Pollution Under Control (PUC) clearances, commercial permits, and comprehensive motor insurance, as mandated by the Motor Vehicles Act, 1988, and relevant state transport rules. While RCM collects and verifies onboarding documentation as an administrative safety precaution, RCM is a technology platform—not a law enforcement or regulatory agency—and cannot guarantee the continuing mechanical fitness or legal compliance of independent vehicles.\n\n'
                          '• Traffic Violations and Fines: RCM bears no liability or accountability for traffic infractions, speeding tickets, illegal parking fines, toll evasions, or motor vehicle law violations committed by a Driver during a trip. All legal liabilities, challans, and penalties rest with the individual Driver and vehicle owner.\n\n'
                          '• Police Verification and Criminal Acts: RCM conducts routine document checks during Driver enrollment. However, any unlawful behavior, criminal acts, negligence, or misconduct by Drivers is their individual responsibility. RCM will cooperate fully with law enforcement authorities by providing trip logs, device data, and User details upon formal legal request.',
                    ),

                    _PolicySection(
                      title: '7. Limitation of Liability and On-Road Incidents',
                      body: '• Passenger Travel at Own Risk: Passengers acknowledge that road travel carries inherent risks. RCM shall not be held directly liable, legally accountable, or financially responsible for any accidents, collisions, vehicle breakdowns, injuries, fatalities, loss of luggage, theft, delays, or consequential damages occurring on-road during a trip.\n\n'
                          '• Insurance Reliance: Passengers and Drivers must rely on the statutory third-party commercial vehicle insurance policy attached to the vehicle or on personal travel or health insurance for any claims arising from transit incidents.\n\n'
                          '• Force Majeure: RCM is not liable for any failure to perform its obligations under this Agreement due to causes beyond its reasonable control, including natural disasters, acts of God, internet outages, server crashes, civil unrest, or government restrictions.',
                    ),

                    _PolicySection(
                      title: '8. User Conduct and Prohibited Activities',
                      body: '• Passenger Responsibilities: Passengers agree not to carry illegal substances, hazardous materials, firearms, or contraband in RCM-facilitated vehicles. Passengers must treat Drivers with respect, avoid abusive language, and refrain from damaging vehicle interiors.\n\n'
                          '• Right of Refusal: Drivers reserve the right to refuse boarding or terminate a ride immediately if a Passenger is heavily intoxicated, violent, abusive, or attempts to overload the vehicle beyond legal seating capacities.',
                    ),

                    _PolicySection(
                      title: '9. Intellectual Property Rights',
                      body: 'All source code, UI/UX designs, application logos, software architecture, trademarks, text content, and domain rights associated with rathodcarsmitra.com and rc_mitra_mobile are the exclusive intellectual property of RCM. Unauthorized reproduction, reverse engineering, or commercial scraping is strictly prohibited.',
                    ),

                    _PolicySection(
                      title: '10. Governing Law, Jurisdiction, and Dispute Resolution',
                      body: '• Governing Law: These Terms shall be interpreted, construed, and governed in accordance with the laws of India, without regard to conflict-of-law principles.\n\n'
                          '• Jurisdiction: In the event of any dispute, claim, or controversy arising out of or relating to these Terms or platform usage, the courts located in Maharashtra (or your primary operating judicial district) shall have exclusive jurisdiction.',
                    ),

                    SizedBox(height: 10),
                    Text(
                      'By clicking “I Agree” or proceeding with a booking on Rathod Cars Mitra, you acknowledge that you have read, understood, and unreservedly accepted these Terms and Conditions.\n\n'
                      'Rathod Cars Mitra (RCM)  |  Terms and Conditions & Privacy Policy',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('I Understand & Agree', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textDark)),
        ],
      ),
    );
  }
}