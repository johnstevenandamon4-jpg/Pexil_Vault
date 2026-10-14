import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vault_item.dart';

class ApiService {
  static const String apiUrl = 'https://jsonplaceholder.typicode.com/photos?_limit=15';

  Future<List<VaultItem>> fetchVaultItems() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        List<VaultItem> items = body.map((dynamic item) => VaultItem.fromJson(item)).toList();
        return items;
      } else {
        throw Exception('Failed to load vault items from server.');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}