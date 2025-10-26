import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/place_suggestion.dart';

class PlacesService {
  final String placesKey =
      dotenv.env['GOOGLE_PLACES_API_KEY'] ??
      dotenv.env['GOOGLE_MAPS_API_KEY'] ??
      '';
  final bool useMock = dotenv.env['USE_MOCK'] == 'true';

  Future<List<PlaceSuggestion>> fetchSuggestions(String input) async {
    if (useMock) {
      // Return mock suggestions after a small delay to simulate network
      await Future.delayed(const Duration(milliseconds: 200));
      if (input.isEmpty) return [];

      return [
            PlaceSuggestion(
              placeId: 'mock1',
              description: 'Central Park, New York',
            ),
            PlaceSuggestion(
              placeId: 'mock2',
              description: 'Times Square, Manhattan',
            ),
            PlaceSuggestion(
              placeId: 'mock3',
              description: 'Brooklyn Bridge, NY',
            ),
          ]
          .where(
            (s) => s.description.toLowerCase().contains(input.toLowerCase()),
          )
          .toList();
    }

    if (placesKey.isEmpty) return [];
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$placesKey&types=geocode',
    );
    final resp = await http.get(url).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 200) {
      final js = json.decode(resp.body);
      final preds = js['predictions'] as List<dynamic>;
      return preds
          .map(
            (p) => PlaceSuggestion(
              placeId: p['place_id'],
              description: p['description'],
            ),
          )
          .toList();
    }
    return [];
  }
}
