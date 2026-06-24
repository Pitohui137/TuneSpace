import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileService {
  ProfileService(this._client);

  final SupabaseClient _client;

  Future<Profile?> getProfile(String id) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<List<Profile>> getAllProfiles() async {
    final data = await _client
        .from('profiles')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => Profile.fromJson(e)).toList();
  }

  Future<void> updateProfile({
    required String id,
    String? nama,
    String? noTelp,
  }) async {
    final updates = <String, dynamic>{};
    if (nama != null) updates['nama'] = nama;
    if (noTelp != null) updates['no_telp'] = noTelp;
    if (updates.isEmpty) return;

    await _client.from('profiles').update(updates).eq('id', id);
  }

  Future<void> updateRole({
    required String id,
    required String role,
  }) async {
    await _client.from('profiles').update({'role': role}).eq('id', id);
  }

  Future<void> deleteProfile(String id) async {
    await _client.from('profiles').delete().eq('id', id);
  }
}
