class SoleCategory {
  final String id;
  final String name;
  final String? iconUrl;

  SoleCategory({required this.id, required this.name, this.iconUrl});

  factory SoleCategory.fromJson(Map<String, dynamic> json) => SoleCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    iconUrl: json['icon_url'] as String?,
  );
}
