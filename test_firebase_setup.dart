import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Setup Test Script
/// Run this to verify your Firebase configuration is working
Future<void> main() async {
  print('🔥 Testing Firebase Setup...\n');

  try {
    // 1. Initialize Firebase
    print('1. Initializing Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully\n');

    // 2. Check project configuration
    print('2. Checking project configuration...');
    final app = Firebase.app();
    print('✅ Project ID: ${app.options.projectId}');
    print('✅ Storage Bucket: ${app.options.storageBucket}');
    
    if (app.options.storageBucket == null || app.options.storageBucket!.isEmpty) {
      print('❌ Storage bucket not configured!');
      print('   Please enable Firebase Storage in your Firebase Console.');
      return;
    }
    print('✅ Storage bucket is configured\n');

    // 3. Test Firebase Auth
    print('3. Testing Firebase Auth...');
    final auth = FirebaseAuth.instance;
    print('✅ Firebase Auth initialized');
    print('   Current user: ${auth.currentUser?.uid ?? 'No user logged in'}\n');

    // 4. Test Firestore
    print('4. Testing Firestore...');
    final firestore = FirebaseFirestore.instance;
    try {
      // Try to write a test document
      await firestore.collection('_test').doc('setup_test').set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Firebase setup test successful',
      });
      print('✅ Firestore write test successful');
      
      // Try to read the test document
      final doc = await firestore.collection('_test').doc('setup_test').get();
      if (doc.exists) {
        print('✅ Firestore read test successful');
      }
      
      // Clean up test document
      await firestore.collection('_test').doc('setup_test').delete();
      print('✅ Firestore cleanup successful\n');
    } catch (e) {
      print('❌ Firestore test failed: $e');
      if (e.toString().contains('permission-denied')) {
        print('   → Update your Firestore security rules');
      }
      print('');
    }

    // 5. Test Firebase Storage
    print('5. Testing Firebase Storage...');
    final storage = FirebaseStorage.instance;
    try {
      // Try to upload a test file
      final testRef = storage.ref().child('_test_availability');
      await testRef.putString('Firebase Storage test successful');
      print('✅ Firebase Storage upload test successful');
      
      // Try to download the test file
      final downloadUrl = await testRef.getDownloadURL();
      print('✅ Firebase Storage download URL test successful');
      
      // Clean up test file
      await testRef.delete();
      print('✅ Firebase Storage cleanup successful\n');
    } catch (e) {
      print('❌ Firebase Storage test failed: $e');
      if (e.toString().contains('object-not-found')) {
        print('   → Enable Firebase Storage in your Firebase Console');
      } else if (e.toString().contains('permission-denied')) {
        print('   → Update your Firebase Storage security rules');
      }
      print('');
    }

    // 6. Summary
    print('🎉 Firebase Setup Test Complete!');
    print('\nNext steps:');
    print('1. If any tests failed, follow the suggested fixes above');
    print('2. Enable Firebase Storage in Firebase Console if needed');
    print('3. Update security rules for Firestore and Storage');
    print('4. Restart your app and try document upload again');

  } catch (e) {
    print('❌ Firebase setup test failed: $e');
    print('\nTroubleshooting:');
    print('1. Check your google-services.json file');
    print('2. Verify your Firebase project configuration');
    print('3. Ensure all Firebase services are enabled');
  }
}
