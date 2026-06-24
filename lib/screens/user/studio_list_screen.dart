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
                      child: ListView.builder(
                        itemCount: _studios.length,
                        itemBuilder: (context, index) {
                          final studio = _studios[index];
                          return StudioCard(
                            studio: studio,
                            onTap: () => context.push('/user/studio/${studio.id}'),
                          );
                        },
                      ),
                    ),
    );
  }
}
