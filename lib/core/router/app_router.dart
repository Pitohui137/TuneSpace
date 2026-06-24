import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile.dart';
import '../../models/studio.dart';
import '../../screens/admin/admin_booking_screen.dart';
import '../../screens/admin/admin_home_screen.dart';
import '../../screens/admin/admin_studio_form_screen.dart';
import '../../screens/admin/admin_studio_screen.dart';
import '../../screens/admin/admin_user_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/user/booking_form_screen.dart';
import '../../screens/user/booking_history_screen.dart';
import '../../screens/user/booking_status_screen.dart';
import '../../screens/user/studio_detail_screen.dart';
import '../../screens/user/studio_list_screen.dart';
import '../../screens/user/user_home_screen.dart';
import '../../services/auth_service.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final AuthService _authService =
      AuthService(Supabase.instance.client);

  static Profile? _cachedProfile;

  static GoRouter createRouter() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      redirect: _redirect,
      refreshListenable: _AuthRefreshNotifier(),
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/user',
          builder: (context, state) => const UserHomeScreen(),
          routes: [
            GoRoute(
              path: 'studios',
              builder: (context, state) => const StudioListScreen(),
            ),
            GoRoute(
              path: 'studio/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return StudioDetailScreen(studioId: id);
              },
            ),
            GoRoute(
              path: 'book/:studioId',
              builder: (context, state) {
                final studioId = state.pathParameters['studioId']!;
                return BookingFormScreen(studioId: studioId);
              },
            ),
            GoRoute(
              path: 'status',
              builder: (context, state) => const BookingStatusScreen(),
            ),
            GoRoute(
              path: 'history',
              builder: (context, state) => const BookingHistoryScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminHomeScreen(),
          routes: [
            GoRoute(
              path: 'studios',
              builder: (context, state) => const AdminStudioScreen(),
            ),
            GoRoute(
              path: 'studios/form',
              builder: (context, state) {
                final studio = state.extra as Studio?;
                return AdminStudioFormScreen(studio: studio);
              },
            ),
            GoRoute(
              path: 'bookings',
              builder: (context, state) => const AdminBookingScreen(),
            ),
            GoRoute(
              path: 'users',
              builder: (context, state) => const AdminUserScreen(),
            ),
          ],
        ),
      ],
    );
  }

  static Future<String?> _redirect(BuildContext context, GoRouterState state) async {
    final isLoggedIn = _authService.isLoggedIn;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';
    final isSplash = state.matchedLocation == '/splash';

    if (isSplash) return null;

    if (!isLoggedIn) {
      return isAuthRoute ? null : '/login';
    }

    _cachedProfile ??= await _authService.getCurrentProfile();
    final profile = _cachedProfile;
    if (profile == null) return '/login';

    if (isAuthRoute) {
      return profile.isAdmin ? '/admin' : '/user';
    }

    final isAdminRoute = state.matchedLocation.startsWith('/admin');
    final isUserRoute = state.matchedLocation.startsWith('/user');

    if (profile.isAdmin && isUserRoute) return '/admin';
    if (!profile.isAdmin && isAdminRoute) return '/user';

    return null;
  }

  static void clearCache() => _cachedProfile = null;

  static void setProfile(Profile profile) => _cachedProfile = profile;
}

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      AppRouter.clearCache();
      notifyListeners();
    });
  }
}
