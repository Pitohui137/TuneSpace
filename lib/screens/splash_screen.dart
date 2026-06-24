import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../core/router/app_router.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (_authService.isLoggedIn) {
      final profile = await _authService.getCurrentProfile();
      if (!mounted) return;

      if (profile != null) {
        AppRouter.setProfile(profile);
        context.go(profile.isAdmin ? '/admin' : '/user');
        return;
      }
    }

    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note, size: 80, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Booking Studio Musik',
              style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
