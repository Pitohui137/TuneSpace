import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
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
      final bookings = await _bookingService.getUserBookings(userId);
      if (mounted) setState(() => _bookings = bookings);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openProof(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Booking')),
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat riwayat...')
          : _bookings.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.history,
                  message: 'Belum ada riwayat booking.',
                )
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: ListView.builder(
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      return BookingCard(
                        booking: booking,
                        footer: booking.hasPaymentProof
                            ? Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () => _openProof(booking.paymentProofUrl!),
                                  icon: const Icon(Icons.receipt_long),
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
