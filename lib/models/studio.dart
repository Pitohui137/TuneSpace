import 'studio_photo.dart';

class Studio {
  const Studio({
    required this.id,
    required this.namaStudio,
    this.deskripsi,
    this.fasilitas,
    required this.hargaPerJam,
    this.fotoUrl,
    this.gallery = const [],
    required this.createdAt,
  });

  final String id;
  final String namaStudio;
  final String? deskripsi;
  final String? fasilitas;
  final double hargaPerJam;
  final String? fotoUrl;
  final List<StudioPhoto> gallery;
  final DateTime createdAt;

  List<String> get allPhotoUrls {
    final urls = <String>[];
    if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      urls.add(fotoUrl!);
    }
    for (final photo in gallery) {
      if (!urls.contains(photo.photoUrl)) {
        urls.add(photo.photoUrl);
      }
    }
    return urls;
  }

  factory Studio.fromJson(Map<String, dynamic> json) {
    final gallery = json['studio_photos'] != null
        ? (json['studio_photos'] as List)
            .map((item) => StudioPhoto.fromJson(item as Map<String, dynamic>))
            .toList()
        : <StudioPhoto>[];
    gallery.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Studio(
      id: json['id'] as String,
      namaStudio: json['nama_studio'] as String,
      deskripsi: json['deskripsi'] as String?,
      fasilitas: json['fasilitas'] as String?,
      hargaPerJam: (json['harga_per_jam'] as num).toDouble(),
      fotoUrl: json['foto_url'] as String?,
      gallery: gallery,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'nama_studio': namaStudio,
        'deskripsi': deskripsi,
        'fasilitas': fasilitas,
        'harga_per_jam': hargaPerJam,
        'foto_url': fotoUrl,
      };
}
