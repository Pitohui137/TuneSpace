import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/studio.dart';

class StudioService {
  StudioService(this._client);

  final SupabaseClient _client;

  Future<List<Studio>> getAllStudios() async {
    final data = await _client
        .from('studios')
        .select()
        .order('nama_studio');
    return (data as List).map((e) => Studio.fromJson(e)).toList();
  }

  Future<Studio?> getStudio(String id) async {
    final data = await _client
        .from('studios')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Studio.fromJson(data);
  }

  Future<void> createStudio(Studio studio) async {
    await _client.from('studios').insert(studio.toJson());
  }

  Future<void> updateStudio(String id, Studio studio) async {
    await _client.from('studios').update(studio.toJson()).eq('id', id);
  }

  Future<void> deleteStudio(String id) async {
    await _client.from('studios').delete().eq('id', id);
  }
}
