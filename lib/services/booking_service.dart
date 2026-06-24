import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';

class BookingService {
  BookingService(this._client);

  final SupabaseClient _client;

  static const _selectWithStudio = '*, studios(*)';
  static const _selectFull = '*, studios(*), profiles(*)';

  Future<List<Booking>> getUserBookings(String userId) async {
    final data = await _client
        .from('bookings')
        .select(_selectWithStudio)
        .eq('user_id', userId)
        .order('tanggal_booking', ascending: false);
    return (data as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<List<Booking>> getAllBookings() async {
    final data = await _client
        .from('bookings')
        .select(_selectFull)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Booking.fromJson(e)).toList();
  }

  Future<Booking?> getBooking(String id) async {
    final data = await _client
        .from('bookings')
        .select(_selectWithStudio)
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Booking.fromJson(data);
  }

  Future<void> createBooking(Booking booking) async {
    await _client.from('bookings').insert(booking.toInsertJson());
  }

  Future<void> updateStatus({
    required String id,
    required String status,
  }) async {
    await _client.from('bookings').update({'status': status}).eq('id', id);
  }

  Future<void> deleteBooking(String id) async {
    await _client.from('bookings').delete().eq('id', id);
  }
}
