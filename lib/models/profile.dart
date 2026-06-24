class Profile {
  const Profile({
    required this.id,
    required this.nama,
    required this.email,
    this.noTelp,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String nama;
  final String email;
  final String? noTelp;
  final String role;
  final DateTime createdAt;

  bool get isAdmin => role == 'admin';

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      nama: json['nama'] as String,
      email: json['email'] as String,
      noTelp: json['no_telp'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'email': email,
        'no_telp': noTelp,
        'role': role,
        'created_at': createdAt.toIso8601String(),
      };
}
