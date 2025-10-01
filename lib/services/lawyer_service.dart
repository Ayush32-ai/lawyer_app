import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LawyerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create or update a lawyer profile in the lawyers collection
  static Future<void> createOrUpdateLawyerProfile({
    required String uid,
    required String name,
    required String email,
    required String licenseNumber,
    required String specialty,
    required int yearsOfExperience,
    required String bio,
    required String phone,
    required double ratePerCase,
    String? currentLocation,
    double? latitude,
    double? longitude,
  }) async {
    try {
      debugPrint('📝 Creating/Updating lawyer profile for: $uid');

      final lawyerData = {
        'uid': uid,
        'name': name,
        'email': email,
        'licenseNumber': licenseNumber,
        'specialty': specialty,
        'yearsOfExperience': yearsOfExperience,
        'bio': bio,
        'phone': phone,
        'ratePerCase': ratePerCase,
        'isVerified': false,
        'userType': 'lawyer',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add location data if available
      if (currentLocation != null) {
        lawyerData['currentLocation'] = currentLocation;
        lawyerData['address'] = currentLocation;
      }
      if (latitude != null) lawyerData['latitude'] = latitude;
      if (longitude != null) lawyerData['longitude'] = longitude;

      // Add createdAt only if it's a new document
      final docRef = _firestore.collection('lawyers').doc(uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        lawyerData['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(lawyerData, SetOptions(merge: true));
      debugPrint('✅ Lawyer profile saved successfully');

      // Verify the data
      final savedDoc = await docRef.get();
      debugPrint('📄 Saved lawyer data: ${savedDoc.data()}');
    } catch (e) {
      debugPrint('❌ Error saving lawyer profile: $e');
      rethrow;
    }
  }

  /// Get lawyer profile by ID
  static Future<Map<String, dynamic>?> getLawyerProfile(String lawyerId) async {
    try {
      final doc = await _firestore.collection('lawyers').doc(lawyerId).get();
      return doc.data();
    } catch (e) {
      debugPrint('❌ Error getting lawyer profile: $e');
      return null;
    }
  }

  /// Update lawyer rate
  static Future<void> updateLawyerRate({
    required String lawyerId,
    required double newRate,
  }) async {
    try {
      await _firestore.collection('lawyers').doc(lawyerId).update({
        'ratePerCase': newRate,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Lawyer rate updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating lawyer rate: $e');
      rethrow;
    }
  }

  /// Update lawyer phone number
  static Future<void> updateLawyerPhone({
    required String lawyerId,
    required String newPhone,
  }) async {
    try {
      await _firestore.collection('lawyers').doc(lawyerId).update({
        'phone': newPhone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Lawyer phone updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating lawyer phone: $e');
      rethrow;
    }
  }
}
