import 'package:flutter/material.dart';

import '../models/vault_item.dart';

class DetailsScreen extends StatelessWidget {
  final VaultItem item;

  const DetailsScreen({
    super.key,
    required this.item,
  });

  static const Color _background = Color(0xFF100D1C);
  static const Color _surface = Color(0xFF1D1830);
  static const Color _accent = Color(0xFFB49AFF);
  static const Color _primaryText = Color(0xFFF5F0FF);
  static const Color _secondaryText = Color(0xFFB7ADC9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(
          item.title,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: _background,
        foregroundColor: _primaryText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 320,
              child: item.imageBytes != null
                  ? Image.memory(
                      item.imageBytes!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _imageError(),
                    )
                  : item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;

                            return const Center(
                              child: CircularProgressIndicator(
                                color: _accent,
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => _imageError(),
                        )
                      : _imageError(),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF39304F),
                      ),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: _primaryText,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Asset Description',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: _secondaryText,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.storage_outlined,
                        color: _accent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.isLocal
                              ? 'Saved in this browser'
                              : 'Loaded from the image API',
                          style: const TextStyle(
                            color: _secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageError() {
    return const ColoredBox(
      color: Color(0xFF29223D),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 64,
          color: _accent,
        ),
      ),
    );
  }
}