class VaultItem {
  final int id;
  final String title;
  final String category;
  final String imageUrl;
  final String description;

  VaultItem({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.description,
  });

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    return VaultItem(
      id: json['id'],
      title: json['title'] ?? 'Untitled Asset',
      category: 'Anime & Game Edit',
      imageUrl: json['url'] ?? 'https://via.placeholder.com/600',
      description: json['description'] ?? 'High-definition character render or clip asset stored securely in the PExil Vault.',
    );
  }
}