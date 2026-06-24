class AppConstants {
  static const String appName = 'TuneSpace';

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
}
