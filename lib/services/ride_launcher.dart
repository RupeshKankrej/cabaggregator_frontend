import 'package:url_launcher/url_launcher.dart';

class RideLauncher {
  static Future<void> openProvider(
    String provider, {
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
  }) async {
    provider = provider.toLowerCase();
    String uriString;
    String fallback;

    if (provider.contains('uber')) {
      uriString =
          'uber://?action=setPickup&pickup[latitude]=$pickupLat&pickup[longitude]=$pickupLng&dropoff[latitude]=$dropLat&dropoff[longitude]=$dropLng';
      fallback = 'https://play.google.com/store/apps/details?id=com.ubercab';
    } else if (provider.contains('ola')) {
      uriString =
          'olacabs://app/launch?lat=$pickupLat&lng=$pickupLng&dlat=$dropLat&dlng=$dropLng&category=mini&utm_source=widget_android&drop_mode=1';
      fallback =
          'https://play.google.com/store/apps/details?id=com.olacabs.customer';
    } else if (provider.contains('rapido')) {
      uriString =
          'rapido://open?pickup_lat=$pickupLat&pickup_lng=$pickupLng&drop_lat=$dropLat&drop_lng=$dropLng';
      fallback =
          'https://play.google.com/store/apps/details?id=com.rapido.passenger';
    } else {
      uriString =
          'https://www.google.com/maps/dir/?api=1&origin=$pickupLat,$pickupLng&destination=$dropLat,$dropLng';
      fallback = '';
    }

    final uri = Uri.parse(uriString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (fallback.isNotEmpty) {
      final furi = Uri.parse(fallback);
      if (await canLaunchUrl(furi)) {
        await launchUrl(furi, mode: LaunchMode.externalApplication);
        return;
      }
    }

    final mapsUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$pickupLat,$pickupLng&destination=$dropLat,$dropLng',
    );
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    }
  }
}
