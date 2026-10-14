import 'package:supabase_flutter/supabase_flutter.dart';

class SeatService {
  final _supabase = Supabase.instance.client;

  /// Fetches all booked seat labels for a specific route and travel date
  Future<List<String>> getBookedSeats({
    required String fromCity,
    required String toCity,
    required String travelDate,
  }) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('selected_seats, booking_status')
          .or('from_location.eq.$fromCity,from_city.eq.$fromCity')
          .or('to_location.eq.$toCity,to_city.eq.$toCity')
          .eq('travel_date', travelDate)
          .neq('booking_status', 'rejected');

      final List<String> occupiedSeats = [];

      for (var row in response) {
        final seatsData = row['selected_seats'];
        if (seatsData != null && seatsData is List) {
          occupiedSeats.addAll(seatsData.map((s) => s.toString()));
        }
      }

      return occupiedSeats.toSet().toList(); // Remove duplicates
    } catch (e) {
      return [];
    }
  }
}