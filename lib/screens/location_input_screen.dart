import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dashboard_screen.dart';

class LocationInputScreen extends StatefulWidget {
  const LocationInputScreen({super.key});

  @override
  State<LocationInputScreen> createState() => _LocationInputScreenState();
}

class _LocationInputScreenState extends State<LocationInputScreen> {
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;
  String? _currentLocation;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location permission is granted
      final permission = await Permission.location.status;
      if (permission.isDenied) {
        final result = await Permission.location.request();
        if (result.isDenied) {
          _showLocationPermissionDialog(
            'Location permission is required to find lawyers near you.',
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission.isPermanentlyDenied) {
        _showLocationPermissionDialog(
          'Location permission is permanently denied. Please enable it in settings to find lawyers near you.',
          showSettings: true,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Convert coordinates to address
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = _buildAddressString(place);

          setState(() {
            _currentLocation = address.isNotEmpty
                ? address
                : '${place.locality ?? place.administrativeArea ?? "Unknown Location"}';
            _isLoading = false;
          });
        } else {
          // Fallback to coordinates if no address found
          setState(() {
            _currentLocation =
                'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
            _isLoading = false;
          });
        }
      } catch (geocodingError) {
        // Fallback to coordinates if geocoding fails
        setState(() {
          _currentLocation =
              'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          _isLoading = false;
        });
        _showErrorSnackBar(
          'Could not get address, but location detected successfully!',
        );
      }

      // Auto-navigate to dashboard after successful location detection
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _currentLocation != null) {
          _navigateToDashboard();
        }
      });
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('TimeoutException')) {
        errorMessage =
            'Location request timed out. Please try again or enter manually.';
      } else if (e.toString().contains('PermissionDeniedException')) {
        errorMessage =
            'Location permission denied. Please enable and try again.';
      } else {
        errorMessage =
            'Failed to get location. Please try again or enter manually.';
      }

      _showErrorSnackBar(errorMessage);
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _buildAddressString(Placemark place) {
    List<String> addressParts = [];

    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }

    return addressParts.join(', ');
  }

  void _showLocationPermissionDialog(
    String message, {
    bool showSettings = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_off, color: Colors.orange[700]),
            const SizedBox(width: 8),
            Text(
              'Location Permission',
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(message, style: GoogleFonts.roboto()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.roboto(color: Colors.grey[600]),
            ),
          ),
          if (showSettings) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: Text(
                'Open Settings',
                style: GoogleFonts.roboto(color: const Color(0xFF2196F3)),
              ),
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _getCurrentLocation(); // Retry
              },
              child: Text(
                'Try Again',
                style: GoogleFonts.roboto(color: const Color(0xFF2196F3)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_disabled, color: Colors.red[700]),
            const SizedBox(width: 8),
            Text(
              'Location Services',
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Location services are disabled. Please enable location services in your device settings to find lawyers near you.',
          style: GoogleFonts.roboto(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.roboto(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: Text(
              'Open Settings',
              style: GoogleFonts.roboto(color: const Color(0xFF2196F3)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _navigateToDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(
          location: _currentLocation ?? _addressController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Where are you?',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Current Location Option
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.my_location, size: 48, color: Colors.blue[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Use Current Location',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Automatically detect your location',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    if (_currentLocation != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.green[600],
                                  size: 20,
                                ),
                                IconButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _getCurrentLocation,
                                  icon: Icon(
                                    Icons.refresh,
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
                                  tooltip: 'Refresh location',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Current Location Found',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentLocation!,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.green[800],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _getCurrentLocation,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.gps_fixed),
                        label: Text(
                          _isLoading
                              ? 'Getting Location...'
                              : 'Get My Location',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: GoogleFonts.roboto(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),

              const SizedBox(height: 32),

              // Manual Address Input
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_location,
                          size: 24,
                          color: Colors.blue[400],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Enter Address Manually',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: 'Enter your address or city',
                        hintStyle: GoogleFonts.roboto(color: Colors.grey[500]),
                        prefixIcon: Icon(
                          Icons.location_on,
                          color: Colors.grey[400],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2196F3),
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_addressController.text.isNotEmpty ||
                        _currentLocation != null) {
                      _navigateToDashboard();
                    } else {
                      _showErrorSnackBar(
                        'Please enter an address or use current location',
                      );
                    }
                  },
                  child: Text(
                    'Continue',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
