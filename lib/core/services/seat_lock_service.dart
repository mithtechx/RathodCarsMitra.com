import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SeatLockService {
  static final SeatLockService _instance = SeatLockService._internal();
  factory SeatLockService() => _instance;
  SeatLockService._internal();

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _seatChannel;

  // Map of locked seats: key = "seatLabel", value = expiry DateTime
  final Map<String, DateTime> _lockedSeats = {};

  ValueNotifier<Map<String, DateTime>> lockedSeatsNotifier = ValueNotifier({});

  void init(String routeId, String travelDate) {
    final channelName = 'seat_locks_${routeId}_$travelDate';
    _seatChannel?.unsubscribe();

    _seatChannel = _supabase.channel(channelName);

    _seatChannel!.onBroadcast(
      event: 'seat_hold',
      callback: (payload) {
        final seat = payload['seat'] as String?;
        if (seat != null) {
          _lockedSeats[seat] = DateTime.now().add(const Duration(minutes: 5));
          lockedSeatsNotifier.value = Map.from(_lockedSeats);
        }
      },
    ).subscribe();
  }

  void broadcastSeatHold(String seat) {
    if (_seatChannel == null) return;
    
    _lockedSeats[seat] = DateTime.now().add(const Duration(minutes: 5));
    lockedSeatsNotifier.value = Map.from(_lockedSeats);

    // Exact method for supabase_flutter / realtime_client v2
    _seatChannel!.sendBroadcastMessage(
      event: 'seat_hold',
      payload: {'seat': seat},
    );
  }

  bool isSeatLockedByAnother(String seat) {
    if (!_lockedSeats.containsKey(seat)) return false;
    if (DateTime.now().isAfter(_lockedSeats[seat]!)) {
      _lockedSeats.remove(seat);
      return false;
    }
    return true;
  }

  void dispose() {
    _seatChannel?.unsubscribe();
  }
}