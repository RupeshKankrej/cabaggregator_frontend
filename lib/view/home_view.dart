import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../controller/ride_controller.dart';
import '../model/place_suggestion.dart';
import 'fare_list_view.dart';
import 'location_picker_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<RideController>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Book a Ride'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Lottie.asset(
                'assets/animations/ride_map.json',
                height: 180,
                repeat: true,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildLocationField(
                      context,
                      icon: Icons.my_location,
                      label: 'Pickup Location',
                      value: controller.source,
                      color: Colors.green,
                      onTap: () async {
                        final result = await Navigator.push<PlaceSuggestion>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LocationPickerView(
                              isSource: true,
                              title: 'Choose Pickup Location',
                            ),
                          ),
                        );
                        if (result != null) {
                          controller.selectSuggestion(result, true);
                        }
                      },
                    ),
                    const Divider(height: 32),
                    _buildLocationField(
                      context,
                      icon: Icons.location_on,
                      label: 'Drop-off Location',
                      value: controller.destination,
                      color: Colors.redAccent,
                      onTap: () async {
                        final result = await Navigator.push<PlaceSuggestion>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LocationPickerView(
                              isSource: false,
                              title: 'Choose Drop-off Location',
                            ),
                          ),
                        );
                        if (result != null) {
                          controller.selectSuggestion(result, false);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await controller.fetchEstimates();
                  if (controller.error == null && context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FareListView()),
                    );
                  } else if (controller.error != null && context.mounted) {
                    // Failure: Show error as SnackBar (Toast)
                    _showErrorSnackBar(context, controller.error!);
                  }
                },
                child: controller.loading
                    ? const SizedBox(
                        height: 26,
                        width: 26,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Compare Rides',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String? value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Text(
                value == null || value.isEmpty ? 'Enter $label' : value,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: value == null || value.isEmpty
                      ? Colors.grey
                      : Colors.black,
                  fontWeight: value == null || value.isEmpty
                      ? FontWeight.w400
                      : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
