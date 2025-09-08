import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProductionDatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize production database with proper structure
  static Future<void> initializeProductionDatabase() async {
    try {
      debugPrint('🚀 Initializing production database...');

      // Create collections with proper structure
      await _createCollections();

      // Add sample lawyer data for production
      await _addSampleLawyers();

      // Set up indexes for better performance
      await _setupIndexes();

      debugPrint('✅ Production database initialized successfully!');
    } catch (e) {
      debugPrint('❌ Error initializing production database: $e');
      rethrow;
    }
  }

  /// Create necessary collections with proper structure
  static Future<void> _createCollections() async {
    try {
      // Create users collection (will be populated as users sign up)
      await _firestore.collection('users').doc('_template').set({
        'email': 'template@example.com',
        'name': 'Template User',
        'userType': 'client',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isTemplate': true,
      });

      // Create documents collection (will be populated as documents are uploaded)
      await _firestore.collection('documents').doc('_template').set({
        'userId': 'template_user',
        'fileName': 'template.pdf',
        'documentType': 'Template',
        'createdAt': FieldValue.serverTimestamp(),
        'isTemplate': true,
      });

      // Create lawyers collection
      await _firestore.collection('lawyers').doc('_template').set({
        'userId': 'template_lawyer',
        'name': 'Template Lawyer',
        'email': 'lawyer@example.com',
        'specialty': 'General Law',
        'isAvailable': true,
        'isTemplate': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Collections created with proper structure');
    } catch (e) {
      debugPrint('⚠️ Could not create template collections: $e');
    }
  }

  /// Add sample lawyer data for production
  static Future<void> _addSampleLawyers() async {
    try {
      final sampleLawyers = [
        {
          'name': 'Sarah Johnson',
          'email': 'sarah.johnson@lawfirm.com',
          'specialty': 'Corporate Law',
          'licenseNumber': 'BAR-001',
          'yearsOfExperience': 8,
          'bio':
              'Experienced corporate lawyer specializing in mergers and acquisitions.',
          'isAvailable': true,
          'isVerified': true,
          'hourlyRate': 250.0,
          'location': 'New York, NY',
          'languages': ['English', 'Spanish'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Michael Chen',
          'email': 'michael.chen@legal.com',
          'specialty': 'Criminal Law',
          'licenseNumber': 'BAR-002',
          'yearsOfExperience': 12,
          'bio':
              'Criminal defense attorney with expertise in white-collar crime.',
          'isAvailable': true,
          'isVerified': true,
          'hourlyRate': 300.0,
          'location': 'Los Angeles, CA',
          'languages': ['English', 'Mandarin'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Emily Rodriguez',
          'email': 'emily.rodriguez@familylaw.com',
          'specialty': 'Family Law',
          'licenseNumber': 'BAR-003',
          'yearsOfExperience': 6,
          'bio':
              'Compassionate family law attorney helping families through difficult times.',
          'isAvailable': true,
          'isVerified': true,
          'hourlyRate': 200.0,
          'location': 'Chicago, IL',
          'languages': ['English', 'Spanish'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'David Thompson',
          'email': 'david.thompson@realestate.com',
          'specialty': 'Real Estate Law',
          'licenseNumber': 'BAR-004',
          'yearsOfExperience': 15,
          'bio':
              'Real estate attorney with extensive experience in commercial property law.',
          'isAvailable': true,
          'isVerified': true,
          'hourlyRate': 275.0,
          'location': 'Miami, FL',
          'languages': ['English'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'name': 'Lisa Wang',
          'email': 'lisa.wang@intellectual.com',
          'specialty': 'Intellectual Property',
          'licenseNumber': 'BAR-005',
          'yearsOfExperience': 10,
          'bio':
              'IP attorney specializing in patents, trademarks, and copyright law.',
          'isAvailable': true,
          'isVerified': true,
          'hourlyRate': 350.0,
          'location': 'San Francisco, CA',
          'languages': ['English', 'Mandarin'],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (int i = 0; i < sampleLawyers.length; i++) {
        final lawyer = sampleLawyers[i];
        await _firestore.collection('lawyers').add(lawyer);
        debugPrint('✅ Added lawyer: ${lawyer['name']}');
      }

      debugPrint('✅ Sample lawyers added to production database');
    } catch (e) {
      debugPrint('❌ Error adding sample lawyers: $e');
    }
  }

  /// Set up database indexes for better performance
  static Future<void> _setupIndexes() async {
    try {
      debugPrint('📊 Setting up database indexes...');

      // Note: Indexes are created automatically by Firestore when queries are made
      // This method documents the recommended indexes for production

      // Recommended indexes for production:
      // 1. Collection: lawyers
      //    Fields: isAvailable (Ascending), specialty (Ascending)
      //    Query: where('isAvailable', isEqualTo: true).where('specialty', isEqualTo: 'Corporate Law')

      // 2. Collection: users
      //    Fields: userType (Ascending), createdAt (Descending)
      //    Query: where('userType', isEqualTo: 'lawyer').orderBy('createdAt', descending: true)

      // 3. Collection: documents
      //    Fields: userId (Ascending), uploadedAt (Descending)
      //    Query: where('userId', isEqualTo: 'user123').orderBy('uploadedAt', descending: true)

      debugPrint(
        '📊 Database indexes will be created automatically on first query',
      );
    } catch (e) {
      debugPrint('⚠️ Could not set up indexes: $e');
    }
  }

  /// Get production database statistics
  static Future<Map<String, dynamic>> getProductionStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final lawyersSnapshot = await _firestore.collection('lawyers').get();
      final documentsSnapshot = await _firestore.collection('documents').get();

      // Filter out template documents
      final realUsers = usersSnapshot.docs
          .where((doc) => !doc.data().containsKey('isTemplate'))
          .length;
      final realLawyers = lawyersSnapshot.docs
          .where((doc) => !doc.data().containsKey('isTemplate'))
          .length;
      final realDocuments = documentsSnapshot.docs
          .where((doc) => !doc.data().containsKey('isTemplate'))
          .length;

      return {
        'totalUsers': realUsers,
        'totalLawyers': realLawyers,
        'totalDocuments': realDocuments,
        'isProduction': true,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Error getting production stats: $e');
      return {
        'totalUsers': 0,
        'totalLawyers': 0,
        'totalDocuments': 0,
        'isProduction': false,
        'error': e.toString(),
      };
    }
  }

  /// Clean up template documents (run once after initialization)
  static Future<void> cleanupTemplates() async {
    try {
      debugPrint('🧹 Cleaning up template documents...');

      // Remove template documents from users collection
      final usersSnapshot = await _firestore.collection('users').get();
      for (final doc in usersSnapshot.docs) {
        if (doc.data().containsKey('isTemplate')) {
          await doc.reference.delete();
        }
      }

      // Remove template documents from documents collection
      final documentsSnapshot = await _firestore.collection('documents').get();
      for (final doc in documentsSnapshot.docs) {
        if (doc.data().containsKey('isTemplate')) {
          await doc.reference.delete();
        }
      }

      // Remove template documents from lawyers collection
      final lawyersSnapshot = await _firestore.collection('lawyers').get();
      for (final doc in lawyersSnapshot.docs) {
        if (doc.data().containsKey('isTemplate')) {
          await doc.reference.delete();
        }
      }

      debugPrint('✅ Template documents cleaned up');
    } catch (e) {
      debugPrint('❌ Error cleaning up templates: $e');
    }
  }

  /// Verify production database health
  static Future<Map<String, dynamic>> verifyProductionHealth() async {
    try {
      debugPrint('🏥 Verifying production database health...');

      final results = <String, dynamic>{};

      // Test Firestore connection
      try {
        await _firestore.collection('_health_check').doc('test').set({
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'healthy',
        });
        await _firestore.collection('_health_check').doc('test').delete();
        results['firestore'] = 'healthy';
      } catch (e) {
        results['firestore'] = 'unhealthy: $e';
      }

      // Test collection access
      try {
        final lawyersCount = await _firestore
            .collection('lawyers')
            .count()
            .get();
        results['lawyersCollection'] =
            'accessible (${lawyersCount.count} documents)';
      } catch (e) {
        results['lawyersCollection'] = 'inaccessible: $e';
      }

      // Test user collection access
      try {
        final usersCount = await _firestore.collection('users').count().get();
        results['usersCollection'] =
            'accessible (${usersCount.count} documents)';
      } catch (e) {
        results['usersCollection'] = 'inaccessible: $e';
      }

      results['overallStatus'] =
          results.values.any((v) => v.toString().contains('unhealthy'))
          ? 'unhealthy'
          : 'healthy';
      results['timestamp'] = DateTime.now().toIso8601String();

      debugPrint('🏥 Production database health check completed');
      return results;
    } catch (e) {
      debugPrint('❌ Error verifying production health: $e');
      return {
        'overallStatus': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}




