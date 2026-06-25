class StudioPhoto {
  const StudioPhoto({
    required this.id,
    required this.studioId,
    required this.photoUrl,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String studioId;
  final String photoUrl;
  final int sortOrder;
  final DateTime createdAt;

  factory StudioPhoto.fromJson(Map<String, dynamic> json) {
    return StudioPhoto(
      id: json['id'] as String,
      studioId: json['studio_id'] as String,
      photoUrl: json['photo_url'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'studio_id': studioId,
        'photo_url': photoUrl,
        'sort_order': sortOrder,
      };
}
