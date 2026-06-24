import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/studio.dart';
import '../../services/studio_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class AdminStudioScreen extends StatefulWidget {
  const AdminStudioScreen({super.key});

  @override
  State<AdminStudioScreen> createState() => _AdminStudioScreenState();
}

class _AdminStudioScreenState extends State<AdminStudioScreen> {
  final _studioService = StudioService(Supabase.instance.client);
  List<Studio> _studios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudios();
  }

  Future<void> _loadStudios() async {
    setState(() => _isLoading = true);
    try {
      final studios = await _studioService.getAllStudios();
      if (mounted) setState(() => _studios = studios);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStudio(Studio studio) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Studio'),
        content: Text('Yakin ingin menghapus "${studio.namaStudio}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _studioService.deleteStudio(studio.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Studio berhasil dihapus.')),
        );
        _loadStudios();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Studio')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/admin/studios/form');
          _loadStudios();
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _studios.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.store_outlined,
                  message: 'Belum ada studio. Tambahkan studio baru.',
                )
              : RefreshIndicator(
                  onRefresh: _loadStudios,
                  child: ListView.builder(
                    itemCount: _studios.length,
                    itemBuilder: (context, index) {
                      final studio = _studios[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(studio.namaStudio,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Rp ${studio.hargaPerJam.toInt()}/jam'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  await context.push('/admin/studios/form', extra: studio);
                                  _loadStudios();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteStudio(studio),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
