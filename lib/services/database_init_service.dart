import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/lawyer.dart';

class DatabaseInitService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize database with sample data
  static Future<void> initializeDatabase() async {
    try {
      debugPrint('🔥 Initializing Firestore Database...');

      // Check if lawyers collection already has data
      final lawyersSnapshot = await _firestore
          .collection('lawyers')
          .limit(1)
          .get();

      if (lawyersSnapshot.docs.isEmpty) {
        debugPrint('📝 Adding sample lawyers to Firestore...');
        await _uploadSampleLawyers();
      } else {
        debugPrint('✅ Lawyers collection already exists with data');
      }

      // Initialize other collections if needed
      await _createIndexes();

      debugPrint('🎉 Database initialization complete!');
    } catch (e) {
      debugPrint('❌ Error initializing database: $e');
    }
  }

  /// Upload sample lawyers to Firestore
  static Future<void> _uploadSampleLawyers() async {
    try {
      final lawyers = _getSampleLawyers();
      final batch = _firestore.batch();

      for (final lawyer in lawyers) {
        final docRef = _firestore.collection('lawyers').doc();
        batch.set(docRef, lawyer);
      }

      await batch.commit();
      debugPrint('✅ Successfully uploaded ${lawyers.length} sample lawyers');
    } catch (e) {
      debugPrint('❌ Error uploading sample lawyers: $e');
      rethrow;
    }
  }

  /// Create database indexes for better performance
  static Future<void> _createIndexes() async {
    try {
      // Note: Firestore indexes are typically created automatically
      // or through the Firebase Console for complex queries
      debugPrint('📊 Database indexes will be created automatically');
    } catch (e) {
      debugPrint('⚠️ Error with database indexes: $e');
    }
  }

  /// Get sample lawyers data for Firestore
  static List<Map<String, dynamic>> _getSampleLawyers() {
    return [
      {
        'name': 'Dr. Sarah Johnson',
        'specialty': 'Criminal Law',
        'distance': 0.8,
        'isAvailable': true,
        'experienceYears': 12,
        'bio':
            'Experienced criminal defense attorney with a proven track record of successful cases. Specializes in white-collar crimes and federal cases.',
        'consultationFee': 250.0,
        'profileImage': '',
        'rating': 4.8,
        'reviewCount': 156,
        'phone': '+1 (555) 123-4567',
        'email': 'sarah.johnson@lawfirm.com',
        'specializations': [
          'Criminal Defense',
          'White Collar Crime',
          'Federal Cases',
        ],
        'location': 'New York, NY',
        'address': '123 Legal Plaza, Suite 500, New York, NY 10001',
        'education': 'Harvard Law School, J.D.',
        'barNumber': 'NY12345',
        'languages': ['English', 'Spanish'],
        'hourlyRate': 400.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Michael Chen',
        'specialty': 'Family Law',
        'distance': 1.2,
        'isAvailable': false,
        'experienceYears': 8,
        'bio':
            'Compassionate family law attorney helping families navigate divorce, custody, and adoption proceedings with care and expertise.',
        'consultationFee': 200.0,
        'profileImage': '',
        'rating': 4.7,
        'reviewCount': 98,
        'phone': '+1 (555) 234-5678',
        'email': 'michael.chen@familylaw.com',
        'specializations': [
          'Divorce',
          'Child Custody',
          'Adoption',
          'Domestic Relations',
        ],
        'location': 'New York, NY',
        'address': '456 Family Court Blvd, New York, NY 10002',
        'education': 'Columbia Law School, J.D.',
        'barNumber': 'NY23456',
        'languages': ['English', 'Mandarin'],
        'hourlyRate': 350.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Emily Rodriguez',
        'specialty': 'Corporate Law',
        'distance': 2.1,
        'isAvailable': true,
        'experienceYears': 15,
        'bio':
            'Corporate law specialist with extensive experience in mergers, acquisitions, and business litigation. Trusted advisor to Fortune 500 companies.',
        'consultationFee': 350.0,
        'profileImage': '',
        'rating': 4.9,
        'reviewCount': 203,
        'phone': '+1 (555) 345-6789',
        'email': 'emily.rodriguez@corplaw.com',
        'specializations': [
          'Corporate Law',
          'M&A',
          'Business Litigation',
          'Securities',
        ],
        'location': 'New York, NY',
        'address': '789 Corporate Center, 40th Floor, New York, NY 10003',
        'education': 'Yale Law School, J.D.',
        'barNumber': 'NY34567',
        'languages': ['English', 'Spanish', 'Portuguese'],
        'hourlyRate': 500.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'David Thompson',
        'specialty': 'Personal Injury',
        'distance': 0.5,
        'isAvailable': true,
        'experienceYears': 10,
        'bio':
            'Personal injury attorney fighting for the rights of accident victims. No fee unless we win your case.',
        'consultationFee': 0.0,
        'profileImage': '',
        'rating': 4.6,
        'reviewCount': 142,
        'phone': '+1 (555) 456-7890',
        'email': 'david.thompson@pilaw.com',
        'specializations': [
          'Personal Injury',
          'Auto Accidents',
          'Slip & Fall',
          'Medical Malpractice',
        ],
        'location': 'New York, NY',
        'address': '321 Justice Ave, New York, NY 10004',
        'education': 'NYU School of Law, J.D.',
        'barNumber': 'NY45678',
        'languages': ['English'],
        'hourlyRate': 300.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Jennifer Williams',
        'specialty': 'Immigration Law',
        'distance': 1.8,
        'isAvailable': false,
        'experienceYears': 7,
        'bio':
            'Immigration attorney helping individuals and families achieve their American dream through skilled legal representation.',
        'consultationFee': 180.0,
        'profileImage': '',
        'rating': 4.8,
        'reviewCount': 89,
        'phone': '+1 (555) 567-8901',
        'email': 'jennifer.williams@immigrationlaw.com',
        'specializations': [
          'Immigration',
          'Visa Applications',
          'Green Cards',
          'Citizenship',
        ],
        'location': 'New York, NY',
        'address': '654 Liberty Street, New York, NY 10005',
        'education': 'Brooklyn Law School, J.D.',
        'barNumber': 'NY56789',
        'languages': ['English', 'Spanish', 'French'],
        'hourlyRate': 275.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Robert Anderson',
        'specialty': 'Real Estate Law',
        'distance': 1.5,
        'isAvailable': true,
        'experienceYears': 14,
        'bio':
            'Real estate attorney specializing in residential and commercial property transactions, zoning issues, and property disputes.',
        'consultationFee': 225.0,
        'profileImage': '',
        'rating': 4.7,
        'reviewCount': 134,
        'phone': '+1 (555) 678-9012',
        'email': 'robert.anderson@realestatelaw.com',
        'specializations': [
          'Real Estate Transactions',
          'Property Law',
          'Zoning',
          'Commercial Real Estate',
        ],
        'location': 'New York, NY',
        'address': '987 Property Plaza, New York, NY 10006',
        'education': 'Fordham Law School, J.D.',
        'barNumber': 'NY67890',
        'languages': ['English'],
        'hourlyRate': 375.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];
  }

  /// Clear all data (for testing purposes)
  static Future<void> clearAllData() async {
    try {
      debugPrint('🗑️ Clearing all Firestore data...');

      // Clear lawyers
      final lawyersSnapshot = await _firestore.collection('lawyers').get();
      final batch = _firestore.batch();

      for (final doc in lawyersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ All data cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing data: $e');
    }
  }

  /// Get database statistics
  static Future<Map<String, int>> getDatabaseStats() async {
    try {
      final lawyersCount =
          (await _firestore.collection('lawyers').get()).docs.length;
      final usersCount =
          (await _firestore.collection('users').get()).docs.length;
      final bookingsCount =
          (await _firestore.collection('bookings').get()).docs.length;

      return {'lawyers': lawyersCount, 'users': 0, 'bookings': bookingsCount};
    } catch (e) {
      debugPrint('❌ Error getting database stats: $e');
      return {'lawyers': 0, 'users': 0, 'bookings': 0};
    }
  }

  /// Create a test user account for development
  static Future<void> createTestUser() async {
    try {
      debugPrint('👤 Creating test user account...');

      // Check if test user already exists
      final testUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'test@lawyerapp.com')
          .get();

      if (testUserQuery.docs.isNotEmpty) {
        debugPrint('✅ Test user already exists');
        return;
      }

      // Create test user document
      await _firestore.collection('users').add({
        'email': 'test@lawyerapp.com',
        'name': 'Test User',
        'userType': 'client',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'phoneNumber': '+1 (555) 000-0000',
        'address': '123 Test Street, Test City, TC 12345',
      });

      debugPrint('✅ Test user created successfully');
      debugPrint('📧 Email: test@lawyerapp.com');
      debugPrint('🔑 Password: test123456');
    } catch (e) {
      debugPrint('❌ Error creating test user: $e');
    }
  }
}
