import 'dart:convert';
import 'dart:typed_data';

import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vault_item.dart';

class LocalAssetStorage {
  static const String _databaseName = 'pexil_vault_database';
  static const String _storeName = 'assets';
  static const String _legacyStorageKey = 'pexil_vault_local_assets';

  Future<Database> _openDatabase() {
    final factory = getIdbFactory();

    return factory.open(
      _databaseName,
      version: 1,
      onUpgradeNeeded: (event) {
        final database = event.database;

        if (!database.objectStoreNames.contains(_storeName)) {
          database.createObjectStore(
            _storeName,
            keyPath: 'id',
          );
        }
      },
    );
  }

  Future<List<VaultItem>> getAll() async {
    final database = await _openDatabase();

    try {
      final transaction = database.transaction(
        _storeName,
        idbModeReadOnly,
      );

      final records = await transaction
          .objectStore(_storeName)
          .getAll();

      await transaction.completed;

      final items = records.map((record) {
        return VaultItem.fromLocalRecord(
          Map<String, dynamic>.from(record as Map),
        );
      }).toList();

      await _migrateLegacyItems(items);

      return items;
    } finally {
      database.close();
    }
  }

  Future<void> save(VaultItem item) async {
    final database = await _openDatabase();

    try {
      final transaction = database.transaction(
        _storeName,
        idbModeReadWrite,
      );

      await transaction.objectStore(_storeName).put(
            item.toLocalRecord(),
          );

      await transaction.completed;
    } finally {
      database.close();
    }
  }

  Future<void> delete(int id) async {
    final database = await _openDatabase();

    try {
      final transaction = database.transaction(
        _storeName,
        idbModeReadWrite,
      );

      await transaction.objectStore(_storeName).delete(id);

      await transaction.completed;
    } finally {
      database.close();
    }
  }

  Future<void> _migrateLegacyItems(
    List<VaultItem> existingItems,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final oldData = preferences.getString(_legacyStorageKey);

    if (oldData == null || oldData.isEmpty) return;

    final decoded = jsonDecode(oldData);

    if (decoded is! List) return;

    final existingIds = existingItems.map((item) => item.id).toSet();

    for (final entry in decoded) {
      final record = Map<String, dynamic>.from(entry as Map);
      final id = record['id'] as int;

      if (existingIds.contains(id)) continue;

      final encoded = record['imageBase64'] as String?;
      if (encoded == null || encoded.isEmpty) continue;

      final bytes = base64Decode(encoded);

      final item = VaultItem(
        id: id,
        title: record['title'] as String,
        category: record['category'] as String,
        imageUrl: '',
        description: record['description'] as String? ??
            'Image uploaded to your PExil Vault collection.',
        imageBytes: Uint8List.fromList(bytes),
        isLocal: true,
      );

      await save(item);
      existingIds.add(id);
    }

    await preferences.remove(_legacyStorageKey);
  }
}