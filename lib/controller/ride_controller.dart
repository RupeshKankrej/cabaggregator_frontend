import 'package:cab_aggregator/model/place_suggestion.dart';
import 'package:cab_aggregator/services/places_service.dart';
import 'package:flutter/material.dart';

import '../model/ride.dart';
import '../services/api_service.dart';

class RideController with ChangeNotifier {
  final ApiService _api = ApiService();
  final PlacesService _places = PlacesService();

  String source = '';
  String destination = '';
  double pickupLat = 0;
  double pickupLng = 0;
  double dropLat = 0;
  double dropLng = 0;

  bool loading = false;
  String? error;
  List<Ride> rides = [];
  int lastTimestamp = 0;

  List<PlaceSuggestion> srcSuggestions = [];
  List<PlaceSuggestion> dstSuggestions = [];

  Future<void> fetchSuggestions(String input, bool isSource) async {
    if (input.isEmpty) {
      if (isSource)
        srcSuggestions = [];
      else
        dstSuggestions = [];
      return;
    }
    final res = await _places.fetchSuggestions(input);
    if (isSource)
      srcSuggestions = res;
    else
      dstSuggestions = res;
    notifyListeners();
  }

  Future<void> selectSuggestion(PlaceSuggestion s, bool isSource) async {
    if (isSource) {
      source = s.description;
      if (s.latitude != null && s.longitude != null) {
        pickupLat = s.latitude!;
        pickupLng = s.longitude!;
      }
    } else {
      destination = s.description;
      if (s.latitude != null && s.longitude != null) {
        dropLat = s.latitude!;
        dropLng = s.longitude!;
      }
    }
    srcSuggestions = [];
    dstSuggestions = [];
    notifyListeners();
  }

  Future<void> fetchEstimates() async {
    if (source.isEmpty || destination.isEmpty) {
      error = 'Please set source and destination.';
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final resp = await _api.fetchRides(
        pickLat: pickupLat,
        pickLng: pickupLng,
        dropLat: dropLat,
        dropLng: dropLng,
      );
      rides = resp.rides;
      lastTimestamp = resp.timestamp;
      Future.delayed(Duration(seconds: 5), () async {
        try {
          final resp2 = await _api.fetchRides(
            pickLat: pickupLat,
            pickLng: pickupLng,
            dropLat: dropLat,
            dropLng: dropLng,
          );
          if (resp2.timestamp != lastTimestamp) {
            rides = resp2.rides;
            lastTimestamp = resp2.timestamp;
            notifyListeners();
          }
        } catch (_) {}
      });
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
