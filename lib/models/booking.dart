import 'profile.dart';
import 'studio.dart';

class Booking {
  const Booking({
    required this.id,
    required this.userId,
    required this.studioId,
    required this.tanggalBooking,
    required this.jamMulai,
    required this.durasiJam,
    required this.totalHarga,
    required this.status,
    required this.createdAt,
    this.studio,
    this.profile,
  });

  final String id;
  final String userId;
  final String studioId;
  final DateTime tanggalBooking;
  final String jamMulai;
  final int durasiJam;
  final double totalHarga;
  final String status;
  final DateTime createdAt;
  final Studio? studio;
  final Profile? profile;

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      studioId: json['studio_id'] as String,
      tanggalBooking: DateTime.parse(json['tanggal_booking'] as String),
      jamMulai: _parseTime(json['jam_mulai']),
      durasiJam: json['durasi_jam'] as int,
      totalHarga: (json['total_harga'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      studio: json['studios'] != null
          ? Studio.fromJson(json['studios'] as Map<String, dynamic>)
          : null,
      profile: json['profiles'] != null
          ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  static String _parseTime(dynamic value) {
    if (value is String) {
      return value.length >= 5 ? value.substring(0, 5) : value;
    }
    return value.toString();
  }

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'studio_id': studioId,
        'tanggal_booking':
            '${tanggalBooking.year}-${tanggalBooking.month.toString().padLeft(2, '0')}-${tanggalBooking.day.toString().padLeft(2, '0')}',
        'jam_mulai': '$jamMulai:00',
        'durasi_jam': durasiJam,
        'total_harga': totalHarga,
        'status': status,
      };
}
