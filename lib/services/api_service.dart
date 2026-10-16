import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/vault_item.dart';

class ApiService {
  static const String apiUrl =
      'https://jsonplaceholder.typicode.com/photos?_limit=15';

  Future<List<VaultItem>> fetchVaultItems() async {
    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'The image server returned status ${response.statusCode}.',
        );
      }

      final decodedData = jsonDecode(response.body);

      if (decodedData is! List) {
        throw Exception('The server returned an unexpected data format.');
      }

      return decodedData
          .map(
            (item) => VaultItem.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } on Exception catch (error) {
      if (error.toString().contains('Exception:')) {
        rethrow;
      }

      throw Exception(
        'Could not connect to the image server. Check your internet connection and try again.',
      );
    }
  }
}
