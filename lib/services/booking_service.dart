import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';
import '../models/studio_availability.dart';

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

  Future<Booking> createBooking(Booking booking) async {
    final data = await _client
        .from('bookings')
        .insert(booking.toInsertJson())
        .select(_selectWithStudio)
        .single();
    return Booking.fromJson(data);
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

  Future<List<StudioAvailability>> getStudioAvailability({
    required String studioId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final data = await _client.rpc(
      'get_studio_booked_slots',
      params: {
        'studio_uuid': studioId,
        'start_date': _toDate(startDate),
        'end_date': _toDate(endDate),
      },
    );

    return (data as List)
        .map((item) => StudioAvailability.fromJson(item))
        .toList();
  }

  Future<Booking> attachPaymentProof({
    required String bookingId,
    required String publicUrl,
    required String fileName,
  }) async {
    final data = await _client.rpc(
      'attach_payment_proof',
      params: {
        'booking_uuid': bookingId,
        'proof_url': publicUrl,
        'file_name': fileName,
      },
    );
    return Booking.fromJson(data as Map<String, dynamic>);
  }

  Future<String> uploadPaymentProof({
    required String bookingId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        '${_client.auth.currentUser!.id}/$bookingId-${DateTime.now().millisecondsSinceEpoch}-$sanitizedName';

    await _client.storage
        .from('payment-proofs')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

    return _client.storage.from('payment-proofs').getPublicUrl(path);
  }

  String _toDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
