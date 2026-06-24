import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile.dart';
import '../../services/profile_service.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final _profileService = ProfileService(Supabase.instance.client);
  List<Profile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await _profileService.getAllProfiles();
      if (mounted) setState(() => _profiles = profiles);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleRole(Profile profile) async {
    final newRole = profile.role == 'admin' ? 'user' : 'admin';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Role'),
        content: Text(
          'Ubah role "${profile.nama}" menjadi $newRole?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _profileService.updateRole(id: profile.id, role: newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role berhasil diubah.')),
        );
        _loadProfiles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  Future<void> _deleteUser(Profile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: Text('Yakin ingin menghapus "${profile.nama}"?'),
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
      await _profileService.deleteProfile(profile.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengguna dihapus.')),
        );
        _loadProfiles();
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
      appBar: AppBar(title: const Text('Kelola Pengguna')),
      body: _isLoading
          ? const LoadingWidget()
          : _profiles.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.people_outline,
                  message: 'Belum ada data pengguna.',
                )
              : RefreshIndicator(
                  onRefresh: _loadProfiles,
                  child: ListView.builder(
                    itemCount: _profiles.length,
                    itemBuilder: (context, index) {
                      final profile = _profiles[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(profile.nama[0].toUpperCase()),
                          ),
                          title: Text(profile.nama,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${profile.email} • ${profile.role}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'role') _toggleRole(profile);
                              if (value == 'delete') _deleteUser(profile);
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'role',
                                child: Text('Ubah Role'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus', style: TextStyle(color: Colors.red)),
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
