import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class BookingStatusScreen extends StatefulWidget {
  const BookingStatusScreen({super.key});

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  final _bookingService = BookingService(Supabase.instance.client);
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final all = await _bookingService.getUserBookings(userId);
      final active = all
          .where((b) => b.status == 'menunggu' || b.status == 'disetujui')
          .toList();
      if (mounted) setState(() => _bookings = active);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadProof(Booking booking) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    try {
      final publicUrl = await _bookingService.uploadPaymentProof(
        bookingId: booking.id,
        fileName: result.files.single.name,
        bytes: result.files.single.bytes!,
      );
      await _bookingService.attachPaymentProof(
        bookingId: booking.id,
        publicUrl: publicUrl,
        fileName: result.files.single.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bukti pembayaran berhasil diunggah.')),
        );
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload bukti: $e')),
        );
      }
    }
  }

  Future<void> _openProof(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status Booking')),
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat status booking...')
          : _bookings.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.pending_actions,
                  message: 'Tidak ada booking aktif saat ini.',
                )
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: ListView.builder(
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      return BookingCard(
                        booking: booking,
                        footer: Row(
                          children: [
                            if (!booking.hasPaymentProof)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _uploadProof(booking),
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Upload Bukti'),
                                ),
                              ),
                            if (booking.hasPaymentProof)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _openProof(booking.paymentProofUrl!),
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('Lihat Bukti'),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
