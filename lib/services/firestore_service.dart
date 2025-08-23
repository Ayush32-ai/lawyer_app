import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/lawyer.dart';

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all lawyers
  Future<List<Lawyer>> getLawyers() async {
    try {
      debugPrint('🔥 Fetching lawyers from Firestore...');
      final QuerySnapshot snapshot = await _firestore
          .collection('lawyers')
          .orderBy('rating', descending: true)
          .get();

      final lawyers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Lawyer.fromFirestore(data, doc.id);
      }).toList();

      debugPrint(
        '✅ Successfully fetched ${lawyers.length} lawyers from Firestore',
      );
      return lawyers;
    } catch (e) {
      debugPrint('❌ Error getting lawyers from Firestore: $e');
      debugPrint('📱 Falling back to mock data...');
      // Return mock data if Firestore fails
      return Lawyer.getMockLawyers();
    }
  }

  /// Get lawyers by location
  Future<List<Lawyer>> getLawyersByLocation(String location) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('lawyers')
          .where('location', isEqualTo: location)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Lawyer.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error getting lawyers by location: $e');
      // Return filtered mock data if Firestore fails
      return Lawyer.getMockLawyers()
          .where(
            (lawyer) =>
                lawyer.location.toLowerCase().contains(location.toLowerCase()),
          )
          .toList();
    }
  }

  /// Get lawyers by specialty
  Future<List<Lawyer>> getLawyersBySpecialty(String specialty) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('lawyers')
          .where('specialty', isEqualTo: specialty)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Lawyer.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error getting lawyers by specialty: $e');
      // Return filtered mock data if Firestore fails
      return Lawyer.getMockLawyers()
          .where(
            (lawyer) =>
                lawyer.specialty.toLowerCase() == specialty.toLowerCase(),
          )
          .toList();
    }
  }

  /// Search lawyers by name or specialty
  Future<List<Lawyer>> searchLawyers(String query) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('lawyers')
          .get();

      final lawyers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Lawyer.fromFirestore(data, doc.id);
      }).toList();

      // Filter by query
      return lawyers.where((lawyer) {
        return lawyer.name.toLowerCase().contains(query.toLowerCase()) ||
            lawyer.specialty.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      debugPrint('Error searching lawyers: $e');
      // Return filtered mock data if Firestore fails
      final query_lower = query.toLowerCase();
      return Lawyer.getMockLawyers().where((lawyer) {
        return lawyer.name.toLowerCase().contains(query_lower) ||
            lawyer.specialty.toLowerCase().contains(query_lower);
      }).toList();
    }
  }

  /// Add a lawyer to favorites
  Future<void> addToFavorites(String userId, String lawyerId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(lawyerId)
          .set({'lawyerId': lawyerId, 'addedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      rethrow;
    }
  }

  /// Remove a lawyer from favorites
  Future<void> removeFromFavorites(String userId, String lawyerId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(lawyerId)
          .delete();
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      rethrow;
    }
  }

  /// Get user's favorite lawyers
  Future<List<String>> getUserFavorites(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting user favorites: $e');
      return [];
    }
  }

  /// Add to recently viewed
  Future<void> addToRecentlyViewed(String userId, String lawyerId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recently_viewed')
          .doc(lawyerId)
          .set({
            'lawyerId': lawyerId,
            'viewedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error adding to recently viewed: $e');
      // Don't rethrow for recently viewed as it's not critical
    }
  }

  /// Get user's recently viewed lawyers
  Future<List<String>> getUserRecentlyViewed(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recently_viewed')
          .orderBy('viewedAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting recently viewed: $e');
      return [];
    }
  }

  /// Save user booking
  Future<void> saveBooking({
    required String userId,
    required String lawyerId,
    required DateTime selectedDate,
    required String selectedTime,
    required Map<String, dynamic> bookingDetails,
  }) async {
    try {
      await _firestore.collection('bookings').add({
        'userId': userId,
        'lawyerId': lawyerId,
        'selectedDate': Timestamp.fromDate(selectedDate),
        'selectedTime': selectedTime,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        ...bookingDetails,
      });
    } catch (e) {
      debugPrint('Error saving booking: $e');
      rethrow;
    }
  }

  /// Get user bookings
  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting user bookings: $e');
      return [];
    }
  }

  /// Upload sample lawyers data (for testing)
  Future<void> uploadSampleLawyers() async {
    try {
      final lawyers = Lawyer.getMockLawyers();
      final batch = _firestore.batch();

      for (final lawyer in lawyers) {
        final docRef = _firestore.collection('lawyers').doc();
        batch.set(docRef, lawyer.toFirestore());
      }

      await batch.commit();
      debugPrint('Sample lawyers uploaded successfully');
    } catch (e) {
      debugPrint('Error uploading sample lawyers: $e');
    }
  }
}
