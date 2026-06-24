import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import 'profile_service.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;
  final ProfileService _profileService = ProfileService(Supabase.instance.client);

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<Profile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return _profileService.getProfile(user.id);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String nama,
    String? noTelp,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'nama': nama,
        'no_telp': noTelp,
        'role': 'user',
      },
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
