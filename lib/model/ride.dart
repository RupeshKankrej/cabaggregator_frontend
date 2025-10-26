class Ride {
  final String provider;
  final String rideType; // e.g. "Mini", "XL"
  final double price;
  final double distanceKm;
  final double durationMin;
  final String? iconUrl;

  Ride({
    required this.provider,
    required this.rideType,
    required this.price,
    required this.distanceKm,
    required this.durationMin,
    this.iconUrl,
  });
}
