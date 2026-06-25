import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/studio.dart';
import '../models/studio_photo.dart';

class StudioService {
  StudioService(this._client);

  final SupabaseClient _client;
  static const _selectStudio = '*, studio_photos(*)';

  Future<List<Studio>> getAllStudios() async {
    final data = await _client
        .from('studios')
        .select(_selectStudio)
        .order('nama_studio');
    return (data as List).map((e) => Studio.fromJson(e)).toList();
  }

  Future<Studio?> getStudio(String id) async {
    final data = await _client
        .from('studios')
        .select(_selectStudio)
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Studio.fromJson(data);
  }

  Future<Studio> createStudio(Studio studio) async {
    final data = await _client
        .from('studios')
        .insert(studio.toJson())
        .select(_selectStudio)
        .single();
    return Studio.fromJson(data);
  }

  Future<void> updateStudio(String id, Studio studio) async {
    await _client.from('studios').update(studio.toJson()).eq('id', id);
  }

  Future<void> deleteStudio(String id) async {
    await _client.from('studios').delete().eq('id', id);
  }

  Future<String> uploadStudioPhoto({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final sanitizedName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        'studio-${DateTime.now().millisecondsSinceEpoch}-$sanitizedName';

    await _client.storage
        .from('studio-photos')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

    return _client.storage.from('studio-photos').getPublicUrl(path);
  }

  Future<void> replaceStudioGallery({
    required String studioId,
    required List<String> photoUrls,
  }) async {
    await _client.from('studio_photos').delete().eq('studio_id', studioId);

    if (photoUrls.isEmpty) return;

    final payload = photoUrls
        .asMap()
        .entries
        .map(
          (entry) => StudioPhoto(
            id: '',
            studioId: studioId,
            photoUrl: entry.value,
            sortOrder: entry.key,
            createdAt: DateTime.now(),
          ).toJson(),
        )
        .toList();

    await _client.from('studio_photos').insert(payload);
  }
}
