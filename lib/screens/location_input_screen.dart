import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/firebase_auth_service.dart';
import '../services/location_service.dart';
import 'dashboard_screen.dart';
import 'lawyer_dashboard_screen.dart';

class LocationInputScreen extends StatefulWidget {
  const LocationInputScreen({super.key});

  @override
  State<LocationInputScreen> createState() => _LocationInputScreenState();
}

class _LocationInputScreenState extends State<LocationInputScreen> {
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;
  String? _currentLocation;
  String? _savedLocation;
  bool _hasExistingLocation = false;

  @override
  void initState() {
    super.initState();
    _checkExistingLocation();
  }

  Future<void> _checkExistingLocation() async {
    try {
      final firebaseAuthService = Provider.of<FirebaseAuthService>(
        context,
        listen: false,
      );

      final currentUser = firebaseAuthService.currentUser;
      if (currentUser != null) {
        final savedLocation = await LocationService.getUserLocation(
          currentUser.uid,
        );
        if (savedLocation != null && savedLocation['address'] != null) {
          setState(() {
            _savedLocation = savedLocation['address'];
            _hasExistingLocation = true;
          });
          debugPrint('📍 Found existing location: $_savedLocation');
        } else {
          debugPrint('📍 No existing location found');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking existing location: $e');
      // Don't show error to user as this is background operation
    }
  }

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

          // Save location to Firebase
          await _saveLocationToFirebase(
            address,
            position.latitude,
            position.longitude,
          );
        } else {
          // Fallback to coordinates if no address found
          final coordinateAddress =
              'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          setState(() {
            _currentLocation = coordinateAddress;
            _isLoading = false;
          });

          // Save location to Firebase
          await _saveLocationToFirebase(
            coordinateAddress,
            position.latitude,
            position.longitude,
          );
        }
      } catch (geocodingError) {
        // Fallback to coordinates if geocoding fails
        final coordinateAddress =
            'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        setState(() {
          _currentLocation = coordinateAddress;
          _isLoading = false;
        });

        // Save location to Firebase
        await _saveLocationToFirebase(
          coordinateAddress,
          position.latitude,
          position.longitude,
        );

        _showErrorSnackBar(
          'Could not get address, but location detected successfully!',
        );
      }

      // Auto-navigate to dashboard after successful location detection
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _currentLocation != null) {
          _navigateToDashboard(_currentLocation!);
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

  Future<void> _saveLocationToFirebase(
    String address,
    double latitude,
    double longitude,
  ) async {
    try {
      debugPrint('📍 Saving location to Firebase: $address');

      if (_hasExistingLocation) {
        // User is updating their location
        await LocationService.updateUserLocation(
          address: address,
          latitude: latitude,
          longitude: longitude,
          additionalData: {
            'source': 'gps',
            'accuracy': 'high',
            'method': 'automatic',
            'isUpdate': true,
          },
        );
      } else {
        // User is setting location for the first time
        await LocationService.saveLocationWithCoordinates(
          latitude: latitude,
          longitude: longitude,
          additionalData: {
            'source': 'gps',
            'accuracy': 'high',
            'method': 'automatic',
          },
        );
      }

      debugPrint('✅ Location saved to Firebase successfully');

      // Show success message
      if (_hasExistingLocation) {
        _showSuccessSnackBar('Location updated successfully!');
      } else {
        _showSuccessSnackBar('Location saved successfully!');
      }
    } catch (e) {
      debugPrint('❌ Error saving location to Firebase: $e');
      // Don't show error to user as this is background operation
    }
  }

  Future<void> _saveManualLocationToFirebase() async {
    if (_addressController.text.trim().isEmpty) return;

    try {
      debugPrint(
        '📍 Saving manual location to Firebase: ${_addressController.text.trim()}',
      );

      if (_hasExistingLocation) {
        // User is updating their location
        await LocationService.updateUserLocation(
          address: _addressController.text.trim(),
          additionalData: {
            'source': 'manual',
            'method': 'user_input',
            'isUpdate': true,
          },
        );
      } else {
        // User is setting location for the first time
        await LocationService.saveUserLocation(
          address: _addressController.text.trim(),
          additionalData: {'source': 'manual', 'method': 'user_input'},
        );
      }

      debugPrint('✅ Manual location saved to Firebase successfully');

      // Show success message
      if (_hasExistingLocation) {
        _showSuccessSnackBar('Location updated successfully!');
      } else {
        _showSuccessSnackBar('Location saved successfully!');
      }
    } catch (e) {
      debugPrint('❌ Error saving manual location to Firebase: $e');
      // Don't show error to user as this is background operation
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Helper method to navigate to appropriate dashboard based on user type
  Future<void> _navigateToDashboard(String location) async {
    try {
      final firebaseAuthService = Provider.of<FirebaseAuthService>(
        context,
        listen: false,
      );

      final currentUser = firebaseAuthService.currentUser;
      if (currentUser != null) {
        // Get user profile to check user type
        final userProfile = await firebaseAuthService.getUserProfile(
          currentUser.uid,
        );

        final userType = userProfile?['userType'] ?? 'client';
        debugPrint('🧭 Navigating to dashboard...');
        debugPrint('📍 Location: $location');
        debugPrint('👤 User type for routing: $userType');

        if (userType == 'lawyer') {
          debugPrint('✅ Routing to LawyerDashboardScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LawyerDashboardScreen(location: location),
            ),
          );
        } else {
          debugPrint('✅ Routing to DashboardScreen (client)');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(location: location),
            ),
          );
        }
      } else {
        // Fallback to client dashboard if no user found
        debugPrint('⚠️ No current user found, defaulting to client dashboard');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(location: location),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error getting user type: $e');
      // Fallback to client dashboard on error
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(location: location),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _hasExistingLocation ? 'Change Your Location' : 'Where are you?',
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

              // Existing Location Section (if user has saved location)
              if (_hasExistingLocation && _savedLocation != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
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
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 32,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You have a saved location',
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[800],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _savedLocation!,
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Use existing location and go to dashboard
                                  _navigateToDashboard(_savedLocation!);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  'Use Saved Location',
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _hasExistingLocation = false;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green[600],
                                  side: BorderSide(color: Colors.green[600]!),
                                ),
                                child: Text(
                                  'Change Location',
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

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
                  onPressed: () async {
                    if (_addressController.text.isNotEmpty ||
                        _currentLocation != null) {
                      // Save manual location if entered
                      if (_addressController.text.isNotEmpty) {
                        await _saveManualLocationToFirebase();
                      }

                      // Navigate to dashboard with new location
                      final newLocation =
                          _currentLocation ?? _addressController.text;
                      _navigateToDashboard(newLocation);
                    } else {
                      _showErrorSnackBar(
                        'Please enter an address or use current location',
                      );
                    }
                  },
                  child: Text(
                    _hasExistingLocation ? 'Update Location' : 'Continue',
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
