import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controller/ride_controller.dart';
import '../services/ride_launcher.dart';

class FareListView extends StatelessWidget {
  const FareListView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Provider.of<RideController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rides'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: ctrl.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Last updated: ${ctrl.lastTimestamp == 0 ? 'Just now' : DateTime.fromMillisecondsSinceEpoch(ctrl.lastTimestamp).toLocal().toString().split('.')[0]}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: ctrl.rides.length,
                    itemBuilder: (context, index) {
                      final r = ctrl.rides[index];
                      final Widget iconWidget = getRideIconWidget(
                        r.provider,
                        r.rideType,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            RideLauncher.openProvider(
                              r.provider,
                              pickupLat: ctrl.pickupLat,
                              pickupLng: ctrl.pickupLng,
                              dropLat: ctrl.dropLat,
                              dropLng: ctrl.dropLng,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.white,
                                    alignment: Alignment.center,
                                    child: iconWidget,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${r.provider} ${r.rideType}',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${r.distanceKm.toStringAsFixed(1)} km • ${r.durationMin.toStringAsFixed(0)} mins',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${r.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Book Now',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // --- icon mapping helper ---
  // Return a widget (Material Icon) for each provider/ride type so we don't
  // depend on external image URLs which can be unreliable.
  Widget getRideIconWidget(String provider, String rideType) {
    final p = provider.toLowerCase();
    final t = rideType.toLowerCase();

    // Default icon
    IconData icon = Icons.directions_car;
    Color color = Colors.green;

    if (p.contains('ola')) {
      icon = Icons.local_taxi;
      if (t.contains('mini'))
        color = Colors.orange;
      else if (t.contains('sedan'))
        color = Colors.blue;
      else if (t.contains('suv'))
        color = Colors.teal;
    } else if (p.contains('uber')) {
      icon = Icons.directions_car;
      if (t.contains('go'))
        color = Colors.deepPurple;
      else if (t.contains('xl'))
        color = Colors.indigo;
      else if (t.contains('premier'))
        color = Colors.black87;
    } else if (p.contains('rapido')) {
      if (t.contains('bike')) {
        icon = Icons.motorcycle;
        color = Colors.orangeAccent;
      } else if (t.contains('auto')) {
        icon = Icons.local_taxi;
        color = Colors.brown;
      } else {
        icon = Icons.motorcycle;
        color = Colors.orangeAccent;
      }
    }

    return Icon(icon, size: 40, color: color);
  }
}
