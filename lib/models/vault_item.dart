import 'dart:typed_data';

class VaultItem {
  final int id;
  final String title;
  final String category;
  final String imageUrl;
  final String description;
  final Uint8List? imageBytes;
  final bool isLocal;

  const VaultItem({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.description,
    this.imageBytes,
    this.isLocal = false,
  });

  factory VaultItem.fromJson(Map<String, dynamic> json) {
    final photoId = json['id'] as int? ?? 0;

    return VaultItem(
      id: photoId,
      title: 'Photo $photoId',
      category: 'Image Asset',
      imageUrl: json['url'] as String? ?? '',
      description:
          'Image asset #$photoId retrieved from the PExil Vault image collection API.',
    );
  }

  factory VaultItem.fromLocalRecord(
    Map<String, dynamic> record,
  ) {
    final storedBytes = record['imageBytes'];

    return VaultItem(
      id: record['id'] as int,
      title: record['title'] as String,
      category: record['category'] as String,
      imageUrl: '',
      description: record['description'] as String? ??
          'Image uploaded to your PExil Vault collection.',
      imageBytes: storedBytes is Uint8List
          ? storedBytes
          : storedBytes is List
              ? Uint8List.fromList(
                  storedBytes.cast<int>(),
                )
              : null,
      isLocal: true,
    );
  }

  Map<String, dynamic> toLocalRecord() {
    if (imageBytes == null) {
      throw StateError('The local image has no image data.');
    }

    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'imageBytes': imageBytes!,
    };
  }
}