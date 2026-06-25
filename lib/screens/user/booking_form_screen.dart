import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../models/booking.dart';
import '../../models/studio.dart';
import '../../models/studio_availability.dart';
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
  String? _errorMessage;

  DateTime _tanggal = DateTime.now().add(const Duration(days: 1));
  String? _selectedJamMulai;
  int _durasiJam = 1;
  List<StudioAvailability> _availability = const [];
  Uint8List? _paymentBytes;
  String? _paymentFileName;

  @override
  void initState() {
    super.initState();
    _loadStudio();
  }

  Future<void> _loadStudio() async {
    try {
      final studio = await _studioService.getStudio(widget.studioId);
      final availability = await _bookingService.getStudioAvailability(
        studioId: widget.studioId,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 60)),
      );

      if (mounted) {
        setState(() {
          _studio = studio;
          _availability = availability;
          _selectedJamMulai = _availableSlotsFor(_tanggal).firstOrNull;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  double get _totalHarga {
    final studio = _studio;
    if (studio == null) return 0;
    return studio.hargaPerJam * _durasiJam;
  }

  List<String> _availableSlotsFor(DateTime date) {
    final bookedHours = <int>{};
    final dayEntries = _availability.where((entry) => _isSameDate(entry.date, date));

    for (final entry in dayEntries) {
      final startHour = int.tryParse(entry.startTime.split(':').first) ?? 0;
      for (var hour = startHour; hour < startHour + entry.durationHours; hour++) {
        bookedHours.add(hour);
      }
    }

    return AppConstants.studioHourSlots.where((slot) {
      final hour = int.parse(slot.split(':').first);
      final requestedHours =
          List.generate(_durasiJam, (index) => hour + index, growable: false);

      final closesAfterHours = requestedHours.any(
        (value) => value >= AppConstants.closingHour,
      );
      if (closesAfterHours) return false;

      return requestedHours.every((value) => !bookedHours.contains(value));
    }).toList();
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isFullyBooked(DateTime date) => _availableSlotsFor(date).isEmpty;

  Future<void> _pickPaymentProof() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;

    setState(() {
      _paymentBytes = result.files.single.bytes!;
      _paymentFileName = result.files.single.name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _selectedJamMulai == null) return;

    setState(() => _isSubmitting = true);

    try {
      final bookingDraft = Booking(
        id: '',
        userId: userId,
        studioId: widget.studioId,
        tanggalBooking: _tanggal,
        jamMulai: _selectedJamMulai!,
        durasiJam: _durasiJam,
        totalHarga: _totalHarga,
        status: 'menunggu',
        createdAt: DateTime.now(),
      );

      var booking = await _bookingService.createBooking(bookingDraft);

      if (_paymentBytes != null && _paymentFileName != null) {
        final publicUrl = await _bookingService.uploadPaymentProof(
          bookingId: booking.id,
          fileName: _paymentFileName!,
          bytes: _paymentBytes!,
        );
        booking = await _bookingService.attachPaymentProof(
          bookingId: booking.id,
          publicUrl: publicUrl,
          fileName: _paymentFileName!,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            booking.hasPaymentProof
                ? 'Booking dan bukti pembayaran berhasil dikirim.'
                : 'Booking berhasil dikirim.',
          ),
        ),
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

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Studio')),
        body: Center(child: Text('Gagal memuat data: $_errorMessage')),
      );
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
    final availableSlots = _availableSlotsFor(_tanggal);

    if (_selectedJamMulai != null && !availableSlots.contains(_selectedJamMulai)) {
      _selectedJamMulai = availableSlots.firstOrNull;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Studio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studio.namaStudio,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currency.format(studio.hargaPerJam)}/jam',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Kalender Ketersediaan Studio',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CalendarDatePicker(
                  initialDate: _tanggal,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                  onDateChanged: (value) {
                    setState(() {
                      _tanggal = value;
                      _selectedJamMulai = _availableSlotsFor(value).firstOrNull;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _LegendChip(
                    color: Colors.green.shade100,
                    label: 'Tersedia',
                    textColor: Colors.green.shade800,
                  ),
                  _LegendChip(
                    color: Colors.red.shade100,
                    label: 'Penuh',
                    textColor: Colors.red.shade800,
                  ),
                  _LegendChip(
                    color: Colors.blue.shade100,
                    label: dateFormat.format(_tanggal),
                    textColor: Colors.blue.shade800,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _isFullyBooked(_tanggal)
                    ? 'Tanggal ini penuh. Silakan pilih tanggal lain.'
                    : 'Jam tersedia pada ${dateFormat.format(_tanggal)}',
                style: TextStyle(
                  color: _isFullyBooked(_tanggal)
                      ? Colors.red.shade700
                      : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedJamMulai,
                decoration: const InputDecoration(labelText: 'Jam Mulai'),
                items: availableSlots
                    .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                    .toList(),
                onChanged: availableSlots.isEmpty
                    ? null
                    : (v) => setState(() => _selectedJamMulai = v),
                validator: (value) {
                  if (availableSlots.isNotEmpty && (value == null || value.isEmpty)) {
                    return 'Pilih jam mulai';
                  }
                  return null;
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
                  if (v != null) {
                    setState(() {
                      _durasiJam = v;
                      _selectedJamMulai = _availableSlotsFor(_tanggal).firstOrNull;
                    });
                  }
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
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _pickPaymentProof,
                icon: const Icon(Icons.upload_file),
                label: Text(
                  _paymentFileName == null
                      ? 'Upload Bukti Pembayaran'
                      : 'Ganti Bukti Pembayaran',
                ),
              ),
              if (_paymentFileName != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _paymentFileName!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Format yang didukung: JPG, PNG, atau PDF.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || availableSlots.isEmpty ? null : _submit,
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

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.color,
    required this.label,
    required this.textColor,
  });

  final Color color;
  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
