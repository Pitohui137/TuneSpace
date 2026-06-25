import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../models/studio.dart';
import '../../models/studio_availability.dart';
import '../../services/booking_service.dart';
import '../../services/studio_service.dart';
import '../../widgets/loading_widget.dart';

class StudioDetailScreen extends StatefulWidget {
  const StudioDetailScreen({super.key, required this.studioId});

  final String studioId;

  @override
  State<StudioDetailScreen> createState() => _StudioDetailScreenState();
}

class _StudioDetailScreenState extends State<StudioDetailScreen> {
  final _studioService = StudioService(Supabase.instance.client);
  final _bookingService = BookingService(Supabase.instance.client);
  final PageController _galleryController = PageController();
  Studio? _studio;
  bool _isLoading = true;
  List<StudioAvailability> _availability = const [];
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStudio();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  Future<void> _loadStudio() async {
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
        _isLoading = false;
      });
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
      return !bookedHours.contains(hour);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Memuat detail studio...'),
      );
    }

    final studio = _studio;
    if (studio == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Studio')),
        body: const Center(child: Text('Studio tidak ditemukan.')),
      );
    }

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final availableSlots = _availableSlotsFor(_selectedDate);
    final photoUrls = studio.allPhotoUrls;
    final heroPhoto = photoUrls.isNotEmpty ? photoUrls.first : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Detail Studio'), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              decoration: BoxDecoration(
                image: heroPhoto != null
                    ? DecorationImage(
                        image: NetworkImage(heroPhoto),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: heroPhoto == null
                    ? LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).colorScheme.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.music_note, size: 40, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    studio.namaStudio,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${currency.format(studio.hargaPerJam)}/jam',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (photoUrls.isNotEmpty) ...[
                      _SectionCard(
                        title: 'Galeri Ruangan',
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: SizedBox(
                                height: 210,
                                width: double.infinity,
                                child: PageView.builder(
                                  controller: _galleryController,
                                  itemCount: photoUrls.length,
                                  onPageChanged: (index) {
                                    setState(() => _currentPhotoIndex = index);
                                  },
                                  itemBuilder: (context, index) {
                                    return Image.network(
                                      photoUrls[index],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.broken_image_outlined,
                                          size: 40,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                photoUrls.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentPhotoIndex == index ? 20 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentPhotoIndex == index
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (studio.deskripsi != null) ...[
                      _SectionCard(
                        title: 'Deskripsi',
                        child: Text(
                          studio.deskripsi!,
                          style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (studio.fasilitas != null) ...[
                      _SectionCard(
                        title: 'Fasilitas',
                        child: Text(
                          studio.fasilitas!,
                          style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _SectionCard(
                      title: 'Kalender Ketersediaan Studio',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CalendarDatePicker(
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 60)),
                            onDateChanged: (value) {
                              setState(() => _selectedDate = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Slot tersedia untuk ${dateFormat.format(_selectedDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          if (availableSlots.isEmpty)
                            Text(
                              'Semua slot pada tanggal ini sudah terisi.',
                              style: TextStyle(color: Colors.red.shade700),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: availableSlots
                                  .map(
                                    (slot) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: Colors.green.shade100),
                                      ),
                                      child: Text(
                                        slot,
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => context.push('/user/book/${studio.id}'),
            child: const Text('Booking Studio'),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
