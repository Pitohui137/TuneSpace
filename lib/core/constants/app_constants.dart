class AppConstants {
  static const String appName = 'TuneSpace';
  static const int openingHour = 8;
  static const int closingHour = 21;

  static const List<String> bookingStatuses = [
    'menunggu',
    'disetujui',
    'ditolak',
    'selesai',
  ];

  static String statusLabel(String status) {
    switch (status) {
      case 'menunggu':
        return 'Menunggu';
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      case 'selesai':
        return 'Selesai';
      default:
        return status;
    }
  }

  static List<String> get studioHourSlots => List.generate(
        closingHour - openingHour,
        (index) => '${(openingHour + index).toString().padLeft(2, '0')}:00',
      );
}
