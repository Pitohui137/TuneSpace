import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/studio.dart';
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
  Studio? _studio;
  bool _isLoading = true;

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

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Studio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.music_note,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              studio.namaStudio,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${currency.format(studio.hargaPerJam)}/jam',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            if (studio.deskripsi != null) ...[
              const Text(
                'Deskripsi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(studio.deskripsi!, style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 24),
            ],
            if (studio.fasilitas != null) ...[
              const Text(
                'Fasilitas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(studio.fasilitas!, style: TextStyle(color: Colors.grey.shade700)),
            ],
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
