import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                    itemBuilder: (context, index) =>
                        BookingCard(booking: _bookings[index]),
                  ),
                ),
    );
  }
}
