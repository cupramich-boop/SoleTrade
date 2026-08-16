class Profile {
  final String id;
  final String username;
  final String? avatarUrl;
  final double ratingScore;
  final int totalSold;
  final String? bio;

  Profile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.ratingScore = 0,
    this.totalSold = 0,
    this.bio,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    username: json['username'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String?,
    ratingScore: (json['rating_score'] as num?)?.toDouble() ?? 0,
    totalSold: json['total_sold'] as int? ?? 0,
    bio: json['bio'] as String?,
  );
}
