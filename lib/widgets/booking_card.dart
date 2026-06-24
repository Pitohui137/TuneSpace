import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../models/booking.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.showUser = false,
  });

  final Booking booking;
  final VoidCallback? onTap;
  final bool showUser;

  Color _statusColor(String status) {
    switch (status) {
      case 'menunggu':
        return Colors.orange;
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'selesai':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.studio?.namaStudio ?? 'Studio',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(booking.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppConstants.statusLabel(booking.status),
                      style: TextStyle(
                        color: _statusColor(booking.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (showUser && booking.profile != null) ...[
                const SizedBox(height: 4),
                Text(
                  booking.profile!.nama,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(dateFormat.format(booking.tanggalBooking)),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text('${booking.jamMulai} (${booking.durasiJam} jam)'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                currency.format(booking.totalHarga),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
