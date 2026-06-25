import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class AdminBookingScreen extends StatefulWidget {
  const AdminBookingScreen({super.key});

  @override
  State<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends State<AdminBookingScreen> {
  final _bookingService = BookingService(Supabase.instance.client);
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _bookingService.getAllBookings();
      if (mounted) setState(() => _bookings = bookings);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(Booking booking, String status) async {
    try {
      await _bookingService.updateStatus(id: booking.id, status: status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status diubah menjadi ${AppConstants.statusLabel(status)}.',
            ),
          ),
        );
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status: $e')),
        );
      }
    }
  }

  Future<void> _openProof(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri);
  }

  void _showActionSheet(Booking booking) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Setujui'),
              onTap: () {
                Navigator.pop(ctx);
                _updateStatus(booking, 'disetujui');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Tolak'),
              onTap: () {
                Navigator.pop(ctx);
                _updateStatus(booking, 'ditolak');
              },
            ),
            ListTile(
              leading: const Icon(Icons.done_all, color: Colors.blue),
              title: const Text('Tandai Selesai'),
              onTap: () {
                Navigator.pop(ctx);
                _updateStatus(booking, 'selesai');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus Booking'),
              onTap: () async {
                Navigator.pop(ctx);
                await _bookingService.deleteBooking(booking.id);
                _loadBookings();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Booking')),
      body: _isLoading
          ? const LoadingWidget()
          : _bookings.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.book_online,
                  message: 'Belum ada data booking.',
                )
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: ListView.builder(
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      return BookingCard(
                        booking: booking,
                        showUser: true,
                        onTap: () => _showActionSheet(booking),
                        footer: booking.hasPaymentProof
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () => _openProof(booking.paymentProofUrl!),
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('Lihat Bukti Pembayaran'),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
    );
  }
}
