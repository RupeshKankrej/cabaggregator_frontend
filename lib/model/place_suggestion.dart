class PlaceSuggestion {
  final String placeId;
  final String description;
  final double? latitude;
  final double? longitude;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.latitude,
    this.longitude,
  });
}
