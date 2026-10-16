class VaultItem {
  final int id;
  final String title;
  final String category;
  final String imageUrl;
  final String description;

  const VaultItem({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.description,
  });

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    final int photoId = json['id'] as int? ?? 0;

    return VaultItem(
      id: photoId,
      title: 'Photo $photoId',
      category: 'Image Asset',
      imageUrl: json['url'] as String? ?? '',
      description:
          'Image asset #$photoId retrieved from the PExil Vault image collection API.',
    );
  }
}
