import 'dart:convert';
import 'package:http/http.dart' as http;

const _apiKey = 'AIzaSyCGU9sIQlRMPVSGi0lHUbjy-t0Ju9yolWU';

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}

class PlaceDetails {
  final String formattedAddress;
  final double latitude;
  final double longitude;

  const PlaceDetails({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });
}

class PlacesService {
  /// Busca sugestões de endereço usando a Places API (New)
  static Future<List<PlacePrediction>> autocomplete(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
      'https://places.googleapis.com/v1/places:autocomplete',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
      },
      body: jsonEncode({
        'input': query,
        'languageCode': 'pt-BR',
        'regionCode': 'BR',
      }),
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final suggestions = data['suggestions'] as List<dynamic>? ?? [];

    return suggestions
        .where((s) => s['placePrediction'] != null)
        .map((s) {
          final p = s['placePrediction'] as Map<String, dynamic>;
          final text = p['structuredFormat'] as Map<String, dynamic>? ?? {};
          return PlacePrediction(
            placeId: p['placeId'] as String? ?? '',
            description: p['text']?['text'] as String? ?? '',
            mainText: text['mainText']?['text'] as String? ?? '',
            secondaryText: text['secondaryText']?['text'] as String? ?? '',
          );
        })
        .toList();
  }

  /// Busca latitude, longitude e endereço formatado de um placeId
  static Future<PlaceDetails?> getDetails(String placeId) async {
    final url = Uri.parse(
      'https://places.googleapis.com/v1/places/$placeId',
    );

    final response = await http.get(
      url,
      headers: {
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'formattedAddress,location',
      },
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final location = data['location'] as Map<String, dynamic>?;

    if (location == null) return null;

    return PlaceDetails(
      formattedAddress: data['formattedAddress'] as String? ?? '',
      latitude: (location['latitude'] as num).toDouble(),
      longitude: (location['longitude'] as num).toDouble(),
    );
  }
}
