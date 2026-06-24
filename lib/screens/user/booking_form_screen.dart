import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/booking.dart';
import '../../models/studio.dart';
import '../../services/booking_service.dart';
import '../../services/studio_service.dart';
import '../../widgets/loading_widget.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key, required this.studioId});

  final String studioId;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studioService = StudioService(Supabase.instance.client);
  final _bookingService = BookingService(Supabase.instance.client);

  Studio? _studio;
  bool _isLoading = true;
  bool _isSubmitting = false;

  DateTime _tanggal = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _jamMulai = const TimeOfDay(hour: 9, minute: 0);
  int _durasiJam = 1;

  static const _jamOptions = ['08:00', '09:00', '10:00', '11:00', '12:00',
      '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00'];

  @override
  void initState() {
    super.initState();
    _loadStudio();
  }

  Future<void> _loadStudio() async {
    final studio = await _studioService.getStudio(widget.studioId);
    if (mounted) {
      setState(() {
        _studio = studio;
        _isLoading = false;
      });
    }
  }

  double get _totalHarga {
    final studio = _studio;
    if (studio == null) return 0;
    return studio.hargaPerJam * _durasiJam;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final jamStr =
          '${_jamMulai.hour.toString().padLeft(2, '0')}:${_jamMulai.minute.toString().padLeft(2, '0')}';

      final booking = Booking(
        id: '',
        userId: userId,
        studioId: widget.studioId,
        tanggalBooking: _tanggal,
        jamMulai: jamStr,
        durasiJam: _durasiJam,
        totalHarga: _totalHarga,
        status: 'menunggu',
        createdAt: DateTime.now(),
      );

      await _bookingService.createBooking(booking);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil dikirim!')),
      );
      context.go('/user/status');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal booking: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget());
    }

    final studio = _studio;
    if (studio == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Studio')),
        body: const Center(child: Text('Studio tidak ditemukan.')),
      );
    }

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Studio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studio.namaStudio,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal Booking'),
                subtitle: Text(dateFormat.format(_tanggal)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const Divider(),
              DropdownButtonFormField<String>(
                initialValue:
                    '${_jamMulai.hour.toString().padLeft(2, '0')}:${_jamMulai.minute.toString().padLeft(2, '0')}',
                decoration: const InputDecoration(labelText: 'Jam Mulai'),
                items: _jamOptions
                    .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  final parts = v.split(':');
                  setState(() {
                    _jamMulai = TimeOfDay(
                      hour: int.parse(parts[0]),
                      minute: int.parse(parts[1]),
                    );
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _durasiJam,
                decoration: const InputDecoration(labelText: 'Durasi (jam)'),
                items: List.generate(
                  8,
                  (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1} jam')),
                ),
                onChanged: (v) {
                  if (v != null) setState(() => _durasiJam = v);
                },
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('Total Harga', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(_totalHarga),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Konfirmasi Booking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
