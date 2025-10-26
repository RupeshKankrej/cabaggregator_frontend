import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:permission_handler/permission_handler.dart';
import '../model/place_suggestion.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LocationPickerView extends StatefulWidget {
  final bool isSource;
  final String title;

  const LocationPickerView({
    super.key,
    required this.isSource,
    required this.title,
  });

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  List<dynamic> _predictions = [];

  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final status = await Permission.location.request();
      if (status.isGranted) {
        setState(() => _loading = true);

        // Create the Android-specific location client
        final GeolocatorAndroid geolocator = GeolocatorAndroid();

        // Get the current position
        final Position position = await geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          ),
        );

        _selectedLocation = LatLng(position.latitude, position.longitude);

        if (_controller.isCompleted) {
          final controller = await _controller.future;
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: _selectedLocation!, zoom: 15),
            ),
          );
        }
      } else {
        setState(() => _error = 'Location permission denied');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchPredictions(String value) async {
    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
      'input=${Uri.encodeComponent(value)}'
      '&key=$apiKey'
      '&components=country:in',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _predictions = data['predictions'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching places: $e');
    }
  }

  Future<void> _selectPrediction(dynamic prediction) async {
    setState(() => _predictions = []);
    _searchController.text = prediction['description'] ?? '';

    final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
    final detailsUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?'
      'place_id=${prediction['place_id']}'
      '&fields=geometry'
      '&key=$apiKey',
    );

    try {
      final detailsResponse = await http.get(detailsUrl);
      if (detailsResponse.statusCode == 200) {
        final detailsData = json.decode(detailsResponse.body);
        if (detailsData['result'] != null &&
            detailsData['result']['geometry'] != null) {
          final location = LatLng(
            detailsData['result']['geometry']['location']['lat'],
            detailsData['result']['geometry']['location']['lng'],
          );
          _onLocationSelected(location, prediction['description']);

          if (_controller.isCompleted) {
            final controller = await _controller.future;
            controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: location, zoom: 15),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error fetching place details: $e');
    } finally {
      // keep focus so user can continue typing if desired
      _searchFocus.requestFocus();
    }
  }

  void _onLocationSelected(LatLng location, String? address) {
    setState(() {
      _selectedLocation = location;
      _selectedAddress = address;
    });
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(
        context,
        PlaceSuggestion(
          placeId:
              'custom_${_selectedLocation!.latitude}_${_selectedLocation!.longitude}',
          description: _selectedAddress ?? 'Selected Location',
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_selectedLocation != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedLocation!,
                zoom: 15,
              ),
              onMapCreated: _controller.complete,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              onTap: (location) async {
                // Get address from coordinates (reverse geocoding)
                _onLocationSelected(location, 'Selected Location');
              },
              markers: _selectedLocation == null
                  ? {}
                  : {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: _selectedLocation!,
                        draggable: true,
                        onDragEnd: (newLocation) {
                          _onLocationSelected(newLocation, 'Selected Location');
                        },
                      ),
                    },
            ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        decoration: InputDecoration(
                          hintText: 'Search location',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: (value) {
                          // Debounce input to avoid spamming API
                          _debounce?.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 300),
                            () {
                              if (value.length > 2) {
                                _fetchPredictions(value);
                              } else {
                                setState(() => _predictions = []);
                              }
                            },
                          );
                        },
                      ),
                      // Inline suggestions list (appears below the TextField)
                      if (_predictions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 240),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _predictions.length,
                            itemBuilder: (context, index) {
                              final prediction = _predictions[index];
                              return ListTile(
                                leading: const Icon(Icons.location_on_outlined),
                                title: Text(prediction['description'] ?? ''),
                                onTap: () => _selectPrediction(prediction),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ),
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),
          if (_selectedLocation != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: ElevatedButton(
                onPressed: _confirmLocation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Confirm Location'),
              ),
            ),
        ],
      ),
    );
  }
}
