import 'package:url_launcher/url_launcher.dart';

class WhatsappService {
  static Future<void> sendWhatsAppMessage({
    required String phone,
    required String message,
  }) async {
    final cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final encodedMsg = Uri.encodeComponent(message);
    final url = Uri.parse('https://wa.me/$cleanedPhone?text=$encodedMsg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // 1. Booking Received / Pending Greeting
  static Future<void> notifyBookingReceived({
    required String phone,
    required String name,
    required String pnr,
    required String pickup,
    required String drop,
    required String date,
    required String time,
  }) async {
    final msg = '''Hello $name! 👋
Thank you for booking with *Rathod Cars Mitra (RCM)*. 

We have received your ride request and it is currently pending UTR/payment verification.

📋 *Booking Details:*
• *PNR:* $pnr
• *Pickup:* $pickup
• *Drop:* $drop
• *Date & Time:* $date at $time

We will notify you as soon as your payment is verified and your ride is confirmed. Have a great day! 🙏''';

    await sendWhatsAppMessage(phone: phone, message: msg);
  }

  // 2. Ride Confirmed Greeting
  static Future<void> notifyRideConfirmed({
    required String phone,
    required String name,
    required String pnr,
    required String pickup,
    required String drop,
    required String date,
    required String time,
  }) async {
    final msg = '''Great news, $name! 🎉
Your payment UTR for PNR *${pnr}* has been successfully verified, and your booking is *CONFIRMED* with *Rathod Cars Mitra (RCM)*!

🚗 *Ride Summary:*
• *PNR:* $pnr
• *Route:* $pickup ➔ $drop
• *Date & Time:* $date at $time

We are assigning your professional driver shortly. Thank you for choosing RCM! 🙏''';

    await sendWhatsAppMessage(phone: phone, message: msg);
  }

  // 3. Driver Dispatched / Allotted Greeting
  static Future<void> notifyDriverDispatched({
    required String phone,
    required String name,
    required String pnr,
    required String driverName,
    required String driverPhone,
    required String carModel,
    required String carNumber,
  }) async {
    final msg = '''Hello $name! 🚗
Your cab has been dispatched for PNR *${pnr}* by *Rathod Cars Mitra (RCM)*!

🧑‍✈️ *Driver Details:*
• *Name:* $driverName
• *Phone:* $driverPhone
• *Vehicle:* $carModel ($carNumber)

Your driver will arrive at the pickup location shortly. Have a safe and comfortable journey with RCM! 🌟''';

    await sendWhatsAppMessage(phone: phone, message: msg);
  }

  // 4. Ride Completed & Review Greeting
  static Future<void> notifyRideCompleted({
    required String phone,
    required String name,
    required String pnr,
  }) async {
    final msg = '''Thank you for riding with us, $name! 🏁
Your trip (PNR: *${pnr}*) has been successfully completed. 

We hope you had a wonderful experience with *Rathod Cars Mitra (RCM)*. We look forward to serving you again soon! Please feel free to share your feedback or book your next ride via our app. 🙏''';

    await sendWhatsAppMessage(phone: phone, message: msg);
  }
}