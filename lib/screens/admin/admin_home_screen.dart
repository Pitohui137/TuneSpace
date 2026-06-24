import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile.dart';
import '../../services/auth_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _authService = AuthService(Supabase.instance.client);
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getCurrentProfile();
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, Admin ${_profile?.nama ?? ''}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Kelola studio, booking, dan pengguna.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            _AdminMenuCard(
              icon: Icons.store,
              title: 'Kelola Studio',
              subtitle: 'Tambah, edit, hapus data studio',
              color: Colors.purple,
              onTap: () => context.push('/admin/studios'),
            ),
            _AdminMenuCard(
              icon: Icons.book_online,
              title: 'Kelola Booking',
              subtitle: 'Setujui atau tolak pemesanan',
              color: Colors.orange,
              onTap: () => context.push('/admin/bookings'),
            ),
            _AdminMenuCard(
              icon: Icons.people,
              title: 'Kelola Pengguna',
              subtitle: 'Lihat dan kelola data pengguna',
              color: Colors.teal,
              onTap: () => context.push('/admin/users'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
