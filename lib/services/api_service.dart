import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cab_aggregator/model/ride.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FareResponse {
  final List<Ride> rides;
  final int timestamp;
  FareResponse({required this.rides, required this.timestamp});
}

class ApiService {
  final String baseUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8080';

  final bool useMock;

  ApiService({bool? useMock})
    : useMock = useMock ?? (dotenv.env['USE_MOCK'] == 'true');

  Future<FareResponse> fetchRides({
    required double pickLat,
    required double pickLng,
    required double dropLat,
    required double dropLng,
  }) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 250));
      final timeStamp = DateTime.now().millisecondsSinceEpoch;

      final rides = <Ride>[
        Ride(
          provider: 'OLA',
          rideType: 'Mini',
          price: 5.50,
          distanceKm: 3.2,
          durationMin: 9.0,
        ),
        Ride(
          provider: 'OLA Prime',
          rideType: 'Sedan',
          price: 6.75,
          distanceKm: 3.2,
          durationMin: 10.0,
        ),
        Ride(
          provider: 'Uber',
          rideType: 'GO',
          price: 8.00,
          distanceKm: 3.2,
          durationMin: 8.0,
        ),
        Ride(
          provider: 'Uber',
          rideType: 'XL',
          price: 10.00,
          distanceKm: 3.2,
          durationMin: 8.0,
        ),
        Ride(
          provider: 'Rapido',
          rideType: 'Bike',
          price: 4.00,
          distanceKm: 3.2,
          durationMin: 8.0,
        ),
        Ride(
          provider: 'Rapido',
          rideType: 'auto',
          price: 6.00,
          distanceKm: 3.2,
          durationMin: 8.0,
        ),
      ];

      return FareResponse(rides: rides, timestamp: timeStamp);
    }

    final uri = Uri.parse('$baseUrl/api/v1/compare');

    // 1. Construct the JSON body matching the CompareRequestDTO
    final requestBody = json.encode({
      'fromLat': pickLat,
      'fromLon': pickLng,
      'toLat': dropLat,
      'toLon': dropLng,
    });

    // 2. Use http.post() instead of http.get() and set Content-Type header
    final resp = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        )
        .timeout(const Duration(seconds: 20));

    if (resp.statusCode == 200) {
      final jsonBody = json.decode(resp.body) as Map<String, dynamic>;

      // 1. Corrected key to 'timeStamp' (camelCase) to match the API response.
      final timeStamp =
          (jsonBody['timeStamp'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch;

      // 2. Look for the 'fareQuotes' array.
      final quotesJson = jsonBody['fareQuotes'] as List<dynamic>?;

      if (quotesJson == null) {
        throw Exception('API response missing "fareQuotes" list.');
      }

      // 3. Map the array of quotes to a List<Ride> objects.
      final rides = quotesJson.map((item) {
        final fare = item as Map<String, dynamic>;
        return Ride(
          provider: fare['provider'] as String,
          rideType: fare['rideType'] as String,
          // Mapped 'estimatedFare' to 'price'
          price: (fare['estimatedFare'] as num).toDouble(),
          distanceKm: (fare['distanceInKm'] as num).toDouble(),
          // Converted 'etaSeconds' to 'durationMin'
          durationMin: (fare['etaSeconds'] as num) / 60.0,
        );
      }).toList();

      return FareResponse(rides: rides, timestamp: timeStamp);
    } else {
      throw Exception('Failed to fetch rides: ${resp.statusCode} ${resp.body}');
    }
  }
}
