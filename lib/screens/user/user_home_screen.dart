import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final _authService = AuthService(Supabase.instance.client);
  final _bookingService = BookingService(Supabase.instance.client);
  Profile? _profile;
  int _activeCount = 0;
  int _historyCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadBookingSummary();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getCurrentProfile();
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _loadBookingSummary() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final bookings = await _bookingService.getUserBookings(userId);
    if (!mounted) return;
    setState(() {
      _activeCount = bookings.where((b) => b.status == 'menunggu' || b.status == 'disetujui').length;
      _historyCount = bookings.length;
    });
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) context.go('/login');
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat pagi';
    if (hour < 18) return 'Selamat siang';
    return 'Selamat sore';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userName = _profile?.nama ?? 'Pengguna';
    final initials = userName.isNotEmpty
        ? userName.trim().split(' ').where((part) => part.isNotEmpty).map((part) => part[0]).take(2).join().toUpperCase()
        : 'TS';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('TuneSpace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 80),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _HeroSection(
                    greeting: _greeting,
                    name: userName,
                    initials: initials,
                    activeCount: _activeCount,
                    onTap: () => context.push('/user/status'),
                    onLogout: _logout,
                  ),
                  const SizedBox(height: 18),
                  _SearchBar(onTap: () => context.push('/user/studios')),
                  const SizedBox(height: 18),
                  _StatusChips(activeCount: _activeCount, historyCount: _historyCount),
                  const SizedBox(height: 18),
                  _SectionHeader(title: 'Fitur Utama', subtitle: 'Akses cepat untuk semua kebutuhan booking'),
                  const SizedBox(height: 12),
                  _ActionRow(
                    actions: [
                      _ActionItem(
                        icon: Icons.storefront_outlined,
                        title: 'Studio',
                        subtitle: 'Cari & pilih studio',
                        color: theme.colorScheme.primary,
                        onTap: () => context.push('/user/studios'),
                      ),
                      _ActionItem(
                        icon: Icons.pending_actions_outlined,
                        title: 'Status',
                        subtitle: 'Booking aktif',
                        color: Colors.deepPurple,
                        onTap: () => context.push('/user/status'),
                      ),
                      _ActionItem(
                        icon: Icons.history_outlined,
                        title: 'Riwayat',
                        subtitle: 'Semua pesananmu',
                        color: Colors.indigo,
                        onTap: () => context.push('/user/history'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Rekomendasi', subtitle: 'Studio populer untuk segera dipesan'),
                  const SizedBox(height: 12),
                  _PromoCard(
                    headline: 'Cinta Ruang Rekaman',
                    detail: 'Studio dengan peralatan lengkap dan harga terjangkau.',
                    badge: 'Best Seller',
                    onTap: () => context.push('/user/studios'),
                  ),
                  const SizedBox(height: 18),
                  _PromoCard(
                    headline: 'Booking Kilat',
                    detail: 'Konfirmasi cepat tanpa proses ribet.',
                    badge: 'Cepat',
                    onTap: () => context.push('/user/studios'),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Tips Profesional', subtitle: 'Gunakan aplikasi dengan lebih optimal'),
                  const SizedBox(height: 12),
                  _TipTile(icon: Icons.upload_file_outlined, text: 'Unggah bukti pembayaran segera agar konfirmasi cepat.'),
                  const SizedBox(height: 12),
                  _TipTile(icon: Icons.calendar_today_outlined, text: 'Pesan lebih awal untuk mendapatkan slot waktu terbaik.'),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.greeting,
    required this.name,
    required this.initials,
    required this.activeCount,
    required this.onTap,
    required this.onLogout,
  });

  final String greeting;
  final String name;
  final String initials;
  final int activeCount;
  final VoidCallback onTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Text(initials, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Lihat Status'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: onLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _MetricChip(label: 'Booking Aktif', value: activeCount.toString()),
                const SizedBox(width: 12),
                _MetricChip(label: 'Status', value: activeCount > 0 ? 'Sedang berjalan' : 'Kosong'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey.shade600),
              const SizedBox(width: 14),
              Expanded(
                child: Text('Cari studio favorit...', style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('Cari', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.activeCount, required this.historyCount});

  final int activeCount;
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatusCard(
            label: 'Aktif',
            value: activeCount.toString(),
            color: Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatusCard(
            label: 'Riwayat',
            value: historyCount.toString(),
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.actions});

  final List<_ActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(children: actions.map((action) => Padding(padding: const EdgeInsets.only(right: 14), child: action)).toList()),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
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
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.headline, required this.detail, required this.badge, required this.onTap});

  final String headline;
  final String detail;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(badge, style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(height: 14),
              Text(headline, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(detail, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Lihat detail', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                  Icon(Icons.arrow_forward, color: Colors.grey.shade500),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 18, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700, height: 1.5))),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
