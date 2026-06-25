class StudioAvailability {
  const StudioAvailability({
    required this.date,
    required this.startTime,
    required this.durationHours,
    required this.status,
  });

  final DateTime date;
  final String startTime;
  final int durationHours;
  final String status;

  factory StudioAvailability.fromJson(Map<String, dynamic> json) {
    return StudioAvailability(
      date: DateTime.parse(json['tanggal_booking'] as String),
      startTime: _parseTime(json['jam_mulai']),
      durationHours: json['durasi_jam'] as int,
      status: json['status'] as String,
    );
  }

  static String _parseTime(dynamic value) {
    final raw = value.toString();
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }
}
