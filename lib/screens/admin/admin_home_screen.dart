import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/profile_service.dart';
import '../../services/studio_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _authService = AuthService(Supabase.instance.client);
  final _profileService = ProfileService(Supabase.instance.client);
  final _studioService = StudioService(Supabase.instance.client);
  final _bookingService = BookingService(Supabase.instance.client);
  Profile? _profile;
  bool _isLoadingStats = true;
  int _studioCount = 0;
  int _bookingCount = 0;
  int _pendingBookingCount = 0;
  int _userCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final results = await Future.wait([
      _authService.getCurrentProfile(),
      _studioService.getAllStudios(),
      _bookingService.getAllBookings(),
      _profileService.getAllProfiles(),
    ]);

    final profile = results[0] as Profile?;
    final studios = results[1] as List;
    final bookings = results[2] as List;
    final profiles = results[3] as List;

    if (mounted) {
      setState(() {
        _profile = profile;
        _studioCount = studios.length;
        _bookingCount = bookings.length;
        _pendingBookingCount = bookings
            .where((item) => item.status == 'menunggu')
            .length;
        _userCount = profiles.length;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
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
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, Admin ${_profile?.nama ?? ''}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pantau studio, booking, dan pengguna dari satu tempat.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MiniBadge(
                        icon: Icons.storefront_outlined,
                        label: 'Studio',
                        value: '$_studioCount',
                      ),
                      _MiniBadge(
                        icon: Icons.pending_actions_outlined,
                        label: 'Menunggu',
                        value: '$_pendingBookingCount',
                      ),
                      _MiniBadge(
                        icon: Icons.people_alt_outlined,
                        label: 'Pengguna',
                        value: '$_userCount',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoadingStats)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _StatCard(
                    title: 'Total Studio',
                    value: '$_studioCount',
                    icon: Icons.mic_external_on_outlined,
                    color: Colors.purple,
                  ),
                  _StatCard(
                    title: 'Total Booking',
                    value: '$_bookingCount',
                    icon: Icons.book_online_outlined,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Booking Menunggu',
                    value: '$_pendingBookingCount',
                    icon: Icons.schedule_outlined,
                    color: Colors.redAccent,
                  ),
                  _StatCard(
                    title: 'Total Pengguna',
                    value: '$_userCount',
                    icon: Icons.groups_2_outlined,
                    color: Colors.teal,
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Text(
              'Menu Cepat',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _AdminMenuCard(
              icon: Icons.store,
              title: 'Kelola Studio',
              subtitle: 'Tambah, edit, hapus data studio dan foto ruangan',
              color: Colors.purple,
              onTap: () => context.push('/admin/studios'),
            ),
            _AdminMenuCard(
              icon: Icons.book_online,
              title: 'Kelola Booking',
              subtitle: 'Tinjau booking dan status pembayaran',
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
