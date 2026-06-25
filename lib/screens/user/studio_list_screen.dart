import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/studio.dart';
import '../../services/studio_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/studio_card.dart';

class StudioListScreen extends StatefulWidget {
  const StudioListScreen({super.key});

  @override
  State<StudioListScreen> createState() => _StudioListScreenState();
}

class _StudioListScreenState extends State<StudioListScreen> {
  final _studioService = StudioService(Supabase.instance.client);
  List<Studio> _studios = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudios();
  }

  Future<void> _loadStudios() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final studios = await _studioService.getAllStudios();
      if (mounted) setState(() => _studios = studios);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Studio')),
      body: _isLoading
          ? const LoadingWidget(message: 'Memuat studio...')
          : _error != null
              ? EmptyStateWidget(
                  icon: Icons.error_outline,
                  message: 'Gagal memuat data: $_error',
                  action: ElevatedButton(
                    onPressed: _loadStudios,
                    child: const Text('Coba Lagi'),
                  ),
                )
              : _studios.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.store_outlined,
                      message: 'Belum ada studio tersedia.',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStudios,
                      child: ListView(
                        children: [
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.secondary,
                                  Theme.of(context).colorScheme.primary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Temukan Studio Favoritmu',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_studios.length} studio siap dipesan hari ini.',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          ..._studios.map(
                            (studio) => StudioCard(
                              studio: studio,
                              onTap: () => context.push('/user/studio/${studio.id}'),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
    );
  }
}
