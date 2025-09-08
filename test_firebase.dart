import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple Firebase configuration test script
/// Run this to diagnose Firebase issues
Future<void> main() async {
  final results = <String, dynamic>{};

  try {
    print('🔥 Testing Firebase Configuration...\n');

    // 1. Check Firebase initialization
    print('1. Checking Firebase initialization...');
    try {
      await Firebase.initializeApp();
      print('✅ Firebase initialized successfully');
      results['initialization'] = {
        'status': 'success',
        'message': 'Firebase initialized',
      };
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      results['initialization'] = {
        'status': 'error',
        'message': 'Firebase initialization failed: $e',
      };
      return;
    }

    // 2. Check project configuration
    print('\n2. Checking project configuration...');
    try {
      final app = Firebase.app();
      print('✅ Project ID: ${app.options.projectId}');
      print('✅ Storage Bucket: ${app.options.storageBucket}');
      print('✅ Database URL: ${app.options.databaseURL}');

      if (app.options.storageBucket == null ||
          app.options.storageBucket!.isEmpty) {
        print('❌ Storage bucket not configured!');
        print('   This is likely the root cause of your issue.');
        print('   Please enable Firebase Storage in your Firebase Console.');
        results['project_config'] = {
          'status': 'error',
          'message': 'Storage bucket not configured!',
        };
      } else {
        print('✅ Storage bucket is configured');
        results['project_config'] = {
          'status': 'success',
          'message': 'Project config checked',
        };
      }
    } catch (e) {
      print('❌ Error checking project config: $e');
      results['project_config'] = {
        'status': 'error',
        'message': 'Error checking project config: $e',
      };
    }

    // 3. Test Firebase Storage
    print('\n3. Testing Firebase Storage...');
    try {
      final storage = FirebaseStorage.instance;
      print('✅ Firebase Storage instance created');

      // Try to list files (this will fail if bucket doesn't exist)
      try {
        await storage.ref().listAll();
        print('✅ Storage bucket is accessible');
        results['storage'] = {
          'status': 'success',
          'message': 'Storage bucket is accessible',
        };
      } catch (e) {
        if (e.toString().contains('object-not-found')) {
          print('⚠️ Storage bucket exists but is empty');
          print('   This is normal for new projects. Storage will work fine.');
          results['storage'] = {
            'status': 'warning',
            'message': 'Storage bucket exists but is empty',
          };
        } else {
          print('❌ Storage bucket not accessible: $e');
          results['storage'] = {
            'status': 'error',
            'message': 'Storage bucket not accessible: $e',
          };
        }
      }
    } catch (e) {
      print('❌ Error testing storage: $e');
      results['storage'] = {
        'status': 'error',
        'message': 'Error testing storage: $e',
      };
    }

    // 4. Test Firestore
    print('\n4. Testing Firestore...');
    try {
      final firestore = FirebaseFirestore.instance;
      print('✅ Firestore instance created');

      // Try a simple operation
      try {
        await firestore.collection('_test').doc('_test').get();
        print('✅ Firestore is accessible');
        results['firestore'] = {
          'status': 'success',
          'message': 'Firestore is accessible',
        };
      } catch (e) {
        if (e.toString().contains('permission-denied')) {
          print('⚠️ Firestore accessible but permission denied');
          print('   This means your security rules are too restrictive.');
          print(
            '   Check the FIRESTORE_SECURITY_RULES_GUIDE.md file for fixes.',
          );
          results['firestore'] = {
            'status': 'warning',
            'message': 'Firestore accessible but permission denied',
          };
        } else {
          print('❌ Firestore not accessible: $e');
          results['firestore'] = {
            'status': 'error',
            'message': 'Firestore not accessible: $e',
          };
        }
      }
    } catch (e) {
      print('❌ Error testing Firestore: $e');
      results['firestore'] = {
        'status': 'error',
        'message': 'Error testing Firestore: $e',
      };
    }

    // 5. Test Firebase Auth
    print('\n5. Testing Firebase Auth...');
    try {
      final auth = FirebaseAuth.instance;
      print('✅ Firebase Auth instance created');
      print('✅ Current user: ${auth.currentUser?.uid ?? 'None'}');
      results['auth'] = {
        'status': 'success',
        'message': 'Firebase Auth instance created',
      };
    } catch (e) {
      print('❌ Error testing Auth: $e');
      results['auth'] = {
        'status': 'error',
        'message': 'Error testing Auth: $e',
      };
    }

    // 6. Summary and recommendations
    print('\n📋 SUMMARY & RECOMMENDATIONS:');
    print('================================');

    final app = Firebase.app();
    if (app.options.storageBucket == null ||
        app.options.storageBucket!.isEmpty) {
      print('❌ MAIN ISSUE: Firebase Storage is not enabled in your project!');
      print('\n🔧 TO FIX THIS:');
      print('1. Go to: https://console.firebase.google.com/');
      print('2. Select your project: ${app.options.projectId}');
      print('3. Click "Storage" in the left sidebar');
      print('4. Click "Get started"');
      print('5. Choose a location for your storage bucket');
      print('6. Set up security rules (start with test mode)');
      print('7. Restart your app after enabling Storage');
    } else {
      print('✅ Firebase Storage is configured');

      // Check for specific issues
      bool hasIssues = false;

      // Check if we had any errors during testing
      if (results.containsKey('storage') &&
          results['storage']['status'] == 'error') {
        print('\n❌ STORAGE ISSUE: ${results['storage']['message']}');
        hasIssues = true;
      }

      if (results.containsKey('firestore') &&
          results['firestore']['status'] == 'error') {
        print('\n❌ FIRESTORE ISSUE: ${results['firestore']['message']}');
        hasIssues = true;
      }

      if (!hasIssues) {
        print('✅ Everything appears to be working correctly!');
        print('   Try uploading a document now.');
      } else {
        print('\n🔧 NEXT STEPS:');
        print('1. Fix any identified issues above');
        print('2. Restart your app');
        print('3. Try uploading a document again');
      }
    }
  } catch (e) {
    print('❌ Test failed with error: $e');
  }
}
