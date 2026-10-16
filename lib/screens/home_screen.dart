import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/vault_item.dart';
import '../services/api_service.dart';
import '../services/local_asset_storage.dart';
import 'details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final LocalAssetStorage _storage = LocalAssetStorage();
  final TextEditingController _searchController =
      TextEditingController();

  List<VaultItem> _allItems = [];
  List<VaultItem> _localItems = [];

  bool _isLoading = true;
  bool _isAddingPhoto = false;
  String? _errorMessage;
  String _searchQuery = '';

  static const Color _background = Color(0xFF100D1C);
  static const Color _surface = Color(0xFF1D1830);
  static const Color _accent = Color(0xFFB49AFF);
  static const Color _textPrimary = Color(0xFFF5F0FF);
  static const Color _textSecondary = Color(0xFFB7ADC9);

  static const List<String> _categories = [
    'Anime',
    'Gacha',
    'Manhwa',
    'Background',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    List<VaultItem> savedItems;

    try {
      savedItems = await _storage.getAll();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Could not read saved photos from browser storage.';
      });
      return;
    }

    try {
      final apiItems = await _apiService.fetchVaultItems();

      if (!mounted) return;

      setState(() {
        _localItems = savedItems;
        _allItems = [...savedItems, ...apiItems];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _localItems = savedItems;
        _allItems = savedItems;
        _errorMessage = savedItems.isEmpty
            ? 'Unable to load sample photos. Check your internet connection and try again.'
            : null;
        _isLoading = false;
      });
    }
  }

  List<VaultItem> get _filteredItems {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return _allItems;

    return _allItems.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _pickAndAddPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty || !mounted) {
        return;
      }

      final file = result.files.single;
      final Uint8List? bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        _showMessage('Could not read that image. Please try another file.');
        return;
      }

      final originalName = file.name;
      final dotIndex = originalName.lastIndexOf('.');
      final suggestedName = dotIndex > 0
          ? originalName.substring(0, dotIndex)
          : originalName;

      final nameController = TextEditingController(
        text: suggestedName,
      );

      String selectedCategory = 'Other';

      final formResult = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: _surface,
                title: const Text(
                  'Add to PExil Vault',
                  style: TextStyle(color: _textPrimary),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          bytes,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        file.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        style: const TextStyle(color: _textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Photo name',
                          labelStyle: const TextStyle(
                            color: _textSecondary,
                          ),
                          filled: true,
                          fillColor: _background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        dropdownColor: _surface,
                        style: const TextStyle(color: _textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: const TextStyle(
                            color: _textSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      final name = nameController.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a photo name.'),
                          ),
                        );
                        return;
                      }

                      Navigator.of(dialogContext).pop({
                        'title': name,
                        'category': selectedCategory,
                      });
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save photo'),
                  ),
                ],
              );
            },
          );
        },
      );

      nameController.dispose();

      if (formResult == null || !mounted) return;

      setState(() => _isAddingPhoto = true);

      final newItem = VaultItem(
        id: -DateTime.now().microsecondsSinceEpoch,
        title: formResult['title']!,
        category: formResult['category']!,
        imageUrl: '',
        description:
            'A photo added from your device to your PExil Vault collection.',
        imageBytes: bytes,
        isLocal: true,
      );

      try {
        await _storage.save(newItem);

        if (!mounted) return;

        setState(() {
          _localItems.insert(0, newItem);
          _allItems.insert(0, newItem);
          _isAddingPhoto = false;
        });

        _showMessage('${newItem.title} saved to this browser.');
      } catch (_) {
        if (!mounted) return;

        setState(() => _isAddingPhoto = false);

        _showMessage(
          'The photo could not be saved. Chrome storage may be full or unavailable.',
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => _isAddingPhoto = false);
      _showMessage('Unable to add this photo. Please try again.');
    }
  }

  Future<void> _deleteItem(VaultItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          'Remove asset?',
          style: TextStyle(color: _textPrimary),
        ),
        content: Text(
          'Remove ${item.title} from your current collection?',
          style: const TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    if (item.isLocal) {
      try {
        await _storage.delete(item.id);
      } catch (_) {
        _showMessage('Could not remove the saved photo.');
        return;
      }
    }

    if (!mounted) return;

    setState(() {
      _allItems.removeWhere((asset) => asset.id == item.id);
      _localItems.removeWhere((asset) => asset.id == item.id);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${item.title} removed from this list.'),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: _accent,
            onPressed: () async {
              if (item.isLocal) {
                try {
                  await _storage.save(item);
                } catch (_) {
                  _showMessage('Could not restore the saved photo.');
                  return;
                }
              }

              if (!mounted) return;

              setState(() {
                if (!_allItems.any((asset) => asset.id == item.id)) {
                  _allItems.add(item);
                  _allItems.sort((a, b) => a.id.compareTo(b.id));
                }

                if (item.isLocal &&
                    !_localItems.any((asset) => asset.id == item.id)) {
                  _localItems.add(item);
                }
              });
            },
          ),
        ),
      );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _textPrimary,
        elevation: 0,
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(
              Icons.auto_awesome_mosaic_rounded,
              color: _accent,
              size: 27,
            ),
            SizedBox(width: 10),
            Text(
              'PExil Vault',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reload collection',
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR CREATIVE SPACE',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your assets, organized.',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Browse and manage your image collection.',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    style: const TextStyle(color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search your collection...',
                      hintStyle: const TextStyle(
                        color: _textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _accent,
                      ),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: _textSecondary,
                              ),
                            ),
                      filled: true,
                      fillColor: _surface,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF39304F),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: _accent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Image collection',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF39304F),
                      ),
                    ),
                    child: Text(
                      _isLoading
                          ? 'Loading...'
                          : '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _isAddingPhoto ? null : _pickAndAddPhoto,
                    icon: _isAddingPhoto
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.add_photo_alternate_outlined,
                          ),
                    label: Text(
                      _isAddingPhoto ? 'Saving...' : 'Add Photo',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: _background,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildContent(items)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<VaultItem> items) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _accent),
            SizedBox(height: 16),
            Text(
              'Loading your collection...',
              style: TextStyle(color: _textSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: _accent,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_library_outlined,
                size: 58,
                color: _accent,
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'Your collection is empty'
                    : 'No matching assets found',
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add a photo or try another search.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textSecondary),
              ),
              if (_searchQuery.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Text('Clear search'),
                ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1000
            ? 5
            : width >= 750
                ? 4
                : width >= 500
                    ? 3
                    : width >= 350
                        ? 2
                        : 1;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: columns == 1 ? 1.45 : 0.76,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return _AssetCard(
              item: item,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DetailsScreen(item: item),
                  ),
                );
              },
              onDelete: () => _deleteItem(item),
            );
          },
        );
      },
    );
  }
}

class _AssetCard extends StatelessWidget {
  final VaultItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AssetCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  static const Color _surface = Color(0xFF1D1830);
  static const Color _accent = Color(0xFFB49AFF);
  static const Color _primaryText = Color(0xFFF5F0FF);
  static const Color _secondaryText = Color(0xFFB7ADC9);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF39304F)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.imageBytes != null)
                    Image.memory(
                      item.imageBytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  else if (item.imageUrl.isNotEmpty)
                    Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return const ColoredBox(
                          color: Color(0xFF29223D),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _accent,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  else
                    _imagePlaceholder(),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Delete ${item.title}',
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        padding: const EdgeInsets.all(8),
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 14,
                        color: _accent,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _secondaryText,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  const Row(
                    children: [
                      Text(
                        'VIEW DETAILS',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.7,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: _accent,
                        size: 13,
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

  Widget _imagePlaceholder() {
    return const ColoredBox(
      color: Color(0xFF29223D),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: _accent,
          size: 42,
        ),
      ),
    );
  }
}