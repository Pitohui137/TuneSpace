import 'package:flutter_test/flutter_test.dart';
import 'package:tunespace/core/constants/app_constants.dart';

void main() {
  test('status label returns correct Indonesian text', () {
    expect(AppConstants.statusLabel('menunggu'), 'Menunggu');
    expect(AppConstants.statusLabel('disetujui'), 'Disetujui');
    expect(AppConstants.statusLabel('ditolak'), 'Ditolak');
    expect(AppConstants.statusLabel('selesai'), 'Selesai');
  });
}
