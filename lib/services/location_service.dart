import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final firebase_auth.FirebaseAuth _auth =
      firebase_auth.FirebaseAuth.instance;

  /// Save user location to Firestore
  static Future<void> saveUserLocation({
    required String address,
    double? latitude,
    double? longitude,
    String? userId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('📍 Saving user location: $address');

      final currentUser = _auth.currentUser;
      final uid = userId ?? currentUser?.uid;

      if (uid == null) {
        throw 'User not authenticated';
      }

      final locationData = {
        'userId': uid,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      debugPrint('📊 Location data to save: $locationData');

      // Save to user's location collection
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('locations')
          .doc('current')
          .set(locationData);

      // Also update the main user document with current location
      await _firestore.collection('users').doc(uid).update({
        'currentLocation': address,
        'latitude': latitude,
        'longitude': longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ User location saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving user location: $e');
      rethrow;
    }
  }

  /// Get user's current location from Firestore
  static Future<Map<String, dynamic>?> getUserLocation(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .doc('current')
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user location: $e');
      return null;
    }
  }

  /// Get user's location update timestamp
  static Future<DateTime?> getLocationUpdateTime(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final data = doc.data();
        final timestamp = data?['locationUpdatedAt'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting location update time: $e');
      return null;
    }
  }

  /// Check if user has any saved location
  static Future<bool> hasUserLocation(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .doc('current')
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('❌ Error checking if user has location: $e');
      return false;
    }
  }

  /// Update user's current location (for location changes)
  static Future<void> updateUserLocation({
    required String address,
    double? latitude,
    double? longitude,
    String? userId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('📍 Updating user location: $address');

      final currentUser = _auth.currentUser;
      final uid = userId ?? currentUser?.uid;

      if (uid == null) {
        throw 'User not authenticated';
      }

      final locationData = {
        'userId': uid,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isUpdated': true,
        ...?additionalData,
      };

      debugPrint('📊 Updated location data: $locationData');

      // Update the current location document
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('locations')
          .doc('current')
          .set(locationData);

      // Also update the main user document with current location
      await _firestore.collection('users').doc(uid).update({
        'currentLocation': address,
        'latitude': latitude,
        'longitude': longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'lastLocationChange': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ User location updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating user location: $e');
      rethrow;
    }
  }

  /// Get location history for a user
  static Future<List<Map<String, dynamic>>> getUserLocationHistory(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('❌ Error getting location history: $e');
      return [];
    }
  }

  /// Save location with reverse geocoding
  static Future<void> saveLocationWithCoordinates({
    required double latitude,
    required double longitude,
    String? userId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('📍 Saving location with coordinates: $latitude, $longitude');

      // Reverse geocoding to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = _buildAddressString(place);

        await saveUserLocation(
          address: address,
          latitude: latitude,
          longitude: longitude,
          userId: userId,
          additionalData: additionalData,
        );
      } else {
        // Fallback to coordinates if no address found
        await saveUserLocation(
          address:
              'Location: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
          latitude: latitude,
          longitude: longitude,
          userId: userId,
          additionalData: additionalData,
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving location with coordinates: $e');
      rethrow;
    }
  }

  /// Build address string from placemark
  static String _buildAddressString(Placemark place) {
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

  /// Get nearby lawyers based on location
  static Future<List<Map<String, dynamic>>> getNearbyLawyers({
    required double latitude,
    required double longitude,
    double radiusInKm = 50.0,
    int limit = 20,
  }) async {
    try {
      debugPrint(
        '🔍 Searching for lawyers within ${radiusInKm}km of $latitude, $longitude',
      );

      // Note: This is a simplified search. For production, you'd want to use
      // Firestore GeoPoint queries or implement proper geospatial indexing
      final querySnapshot = await _firestore
          .collection('lawyers')
          .where('isAvailable', isEqualTo: true)
          .limit(limit)
          .get();

      final lawyers = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final lawyerData = doc.data();
        final lawyerLat = lawyerData['latitude'] as double?;
        final lawyerLng = lawyerData['longitude'] as double?;

        if (lawyerLat != null && lawyerLng != null) {
          final distance =
              Geolocator.distanceBetween(
                latitude,
                longitude,
                lawyerLat,
                lawyerLng,
              ) /
              1000; // Convert to km

          if (distance <= radiusInKm) {
            lawyerData['distance'] = distance;
            lawyerData['id'] = doc.id;
            lawyers.add(lawyerData);
          }
        }
      }

      // Sort by distance
      lawyers.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
      );

      debugPrint('✅ Found ${lawyers.length} nearby lawyers');
      return lawyers;
    } catch (e) {
      debugPrint('❌ Error getting nearby lawyers: $e');
      return [];
    }
  }
}
