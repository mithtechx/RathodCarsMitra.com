import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_model.dart';

class DriverService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all active drivers for Admin Assignment
  Future<List<DriverModel>> fetchActiveDrivers() async {
    try {
      final response = await _supabase
          .from('drivers')
          .select()
          .eq('is_on_duty', true)
          .order('full_name');

      return (response as List).map((json) => DriverModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
      rethrow;
    }
  }

  // Toggle Driver On-Duty / Off-Duty status
  Future<void> toggleDutyStatus(String driverId, bool isOnDuty) async {
    try {
      await _supabase
          .from('drivers')
          .update({'is_on_duty': isOnDuty})
          .eq('id', driverId);
    } catch (e) {
      debugPrint('Error toggling duty status: $e');
      rethrow;
    }
  }

  // Admin Function: Assign Driver to all bookings for a specific Route & Travel Date
  Future<void> assignDriverToTrip({
    required String driverId,
    required String driverName,
    required String driverPhone,
    required String vehicleNumber,
    required String travelDate,
    required String fromLocation,
    required String toLocation,
  }) async {
    try {
      await _supabase
          .from('bookings')
          .update({
            'driver_id': driverId,
            'driver_name': driverName,
            'driver_phone': driverPhone,
            'vehicle_number': vehicleNumber,
            'trip_status': 'assigned',
          })
          .eq('travel_date', travelDate)
          .eq('from_location', fromLocation)
          .eq('to_location', toLocation)
          .neq('booking_status', 'cancelled');
    } catch (e) {
      debugPrint('Error assigning driver to trip: $e');
      rethrow;
    }
  }
}