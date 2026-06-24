class Studio {
  const Studio({
    required this.id,
    required this.namaStudio,
    this.deskripsi,
    this.fasilitas,
    required this.hargaPerJam,
    this.fotoUrl,
    required this.createdAt,
  });

  final String id;
  final String namaStudio;
  final String? deskripsi;
  final String? fasilitas;
  final double hargaPerJam;
  final String? fotoUrl;
  final DateTime createdAt;

  factory Studio.fromJson(Map<String, dynamic> json) {
    return Studio(
      id: json['id'] as String,
      namaStudio: json['nama_studio'] as String,
      deskripsi: json['deskripsi'] as String?,
      fasilitas: json['fasilitas'] as String?,
      hargaPerJam: (json['harga_per_jam'] as num).toDouble(),
      fotoUrl: json['foto_url'] as String?,
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
