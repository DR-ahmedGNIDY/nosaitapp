/// تعليق على عنصر ألبوم (صورة/فيديو).
class AlbumComment {
  final String id;
  final String userType; // 'admin' | 'player'
  final String authorName;
  final String text;
  final DateTime? createdAt;
  final bool isMine;

  const AlbumComment({
    required this.id,
    required this.userType,
    required this.authorName,
    required this.text,
    required this.createdAt,
    required this.isMine,
  });

  factory AlbumComment.fromJson(Map<String, dynamic> json) {
    return AlbumComment(
      id: json['id'] as String? ?? '',
      userType: json['userType'] as String? ?? 'admin',
      authorName: json['authorName'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      isMine: json['isMine'] as bool? ?? false,
    );
  }
}

/// عنصر صورة/فيديو في ألبوم الأكاديمية، مع حالة الإعجاب والتعليقات.
class AlbumImage {
  final String id;
  final String academyId;
  final String title;
  final String description;
  final String imageUrl;
  final int order;
  final String mediaType; // 'image' | 'video'
  final int likesCount;
  final bool isLiked;
  final int commentsCount;
  final List<AlbumComment> comments;

  const AlbumImage({
    required this.id,
    required this.academyId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.order,
    this.mediaType = 'image',
    this.likesCount = 0,
    this.isLiked = false,
    this.commentsCount = 0,
    this.comments = const [],
  });

  bool get isVideo => mediaType == 'video';

  factory AlbumImage.fromJson(Map<String, dynamic> json) {
    return AlbumImage(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      mediaType: json['mediaType'] as String? ?? 'image',
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as List<dynamic>? ?? [])
          .map((e) => AlbumComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  AlbumImage copyWith({
    int? likesCount,
    bool? isLiked,
    int? commentsCount,
    List<AlbumComment>? comments,
  }) {
    return AlbumImage(
      id: id,
      academyId: academyId,
      title: title,
      description: description,
      imageUrl: imageUrl,
      order: order,
      mediaType: mediaType,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      commentsCount: commentsCount ?? this.commentsCount,
      comments: comments ?? this.comments,
    );
  }
}
