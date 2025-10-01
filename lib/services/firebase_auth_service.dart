import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_type.dart';

class FirebaseAuthService extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  firebase_auth.User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  // User profile data
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? get userProfile => _userProfile;

  FirebaseAuthService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((firebase_auth.User? user) {
      if (user != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  /// Sign in with email and password
  Future<firebase_auth.UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Starting login process for: $email');
      debugPrint('🔑 Password length: ${password.length}');

      debugPrint('🚀 Attempting Firebase Auth sign in...');
      final firebase_auth.UserCredential result = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        debugPrint('✅ Firebase Auth login successful: ${result.user!.uid}');
        debugPrint('👤 User email: ${result.user!.email}');
        debugPrint('👤 User display name: ${result.user!.displayName}');

        try {
          await _loadUserProfile();
          debugPrint('✅ User profile loaded after login');
        } catch (e) {
          debugPrint('⚠️ Could not load user profile: $e');
        }
      } else {
        debugPrint('❌ Login result is null');
      }

      return result;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
        '🔥 Firebase Auth Exception during login: ${e.code} - ${e.message}',
      );
      debugPrint('🔥 Exception details: ${e.toString()}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected error during login: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      throw 'An unexpected error occurred during login. Please try again.';
    }
  }

  /// Sign up with email and password
  Future<firebase_auth.UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserType userType,
    required Map<String, dynamic> additionalData,
  }) async {
    try {
      debugPrint('🔐 Starting signup process for: $email');
      debugPrint('👤 User type: ${userType.name}');
      debugPrint('📝 Additional data: $additionalData');

      final firebase_auth.UserCredential result = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        debugPrint('✅ Firebase Auth user created: ${result.user!.uid}');

        // Update display name
        try {
          await result.user!.updateDisplayName(name);
          debugPrint('✅ Display name updated: $name');
        } catch (e) {
          debugPrint('⚠️ Could not update display name: $e');
        }

        // Create user profile in Firestore (don't wait for completion)
        _createUserProfileInBackground(
          user: result.user!,
          name: name,
          userType: userType,
          additionalData: additionalData,
        );

        // Don't wait for profile loading - return success immediately
        debugPrint(
          '✅ Signup completed successfully for: ${result.user!.email}',
        );
      }

      return result;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
        '🔥 Firebase Auth Exception during signup: ${e.code} - ${e.message}',
      );
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected error during signup: $e');
      throw 'An unexpected error occurred during signup. Please try again.';
    }
  }

  /// Create user profile in Firestore in background (non-blocking)
  Future<void> _createUserProfileInBackground({
    required firebase_auth.User user,
    required String name,
    required UserType userType,
    required Map<String, dynamic> additionalData,
  }) async {
    try {
      debugPrint('📝 Creating user profile in Firestore for: ${user.uid}');
      debugPrint('👤 User type: ${userType.name}');

      final profileData = {
        'uid': user.uid,
        'email': user.email,
        'name': name,
        'userType': userType.name,
        'createdAt': DateTime.now()
            .toIso8601String(), // Use local timestamp instead of server timestamp
        'updatedAt': DateTime.now().toIso8601String(),
        ...additionalData,
      };

      debugPrint('📊 Profile data to save: $profileData');

      // Save to appropriate collection based on user type
      String collectionName = userType == UserType.lawyer ? 'lawyers' : 'users';

      await _firestore
          .collection(collectionName)
          .doc(user.uid)
          .set(profileData);
      debugPrint(
        '✅ User profile saved to $collectionName collection successfully',
      );

      // Verify the data was saved
      final savedDoc = await _firestore
          .collection(collectionName)
          .doc(user.uid)
          .get();
      if (savedDoc.exists) {
        debugPrint(
          '✅ Verified: User profile exists in $collectionName collection',
        );
        debugPrint('📄 Saved data: ${savedDoc.data()}');
      } else {
        debugPrint(
          '❌ Verification failed: User profile not found in $collectionName collection',
        );
      }
    } catch (e) {
      debugPrint('❌ Error creating user profile: $e');
      debugPrint('❌ Error details: ${e.runtimeType}');
      // Don't rethrow - this is background process
    }
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    if (_auth.currentUser == null) return;

    try {
      // First try to find in lawyers collection
      var doc = await _firestore
          .collection('lawyers')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        _userProfile = doc.data();
        debugPrint('✅ Loaded lawyer profile from lawyers collection');
        notifyListeners();
        return;
      }

      // If not found in lawyers, try users collection
      doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (doc.exists) {
        _userProfile = doc.data();
        debugPrint('✅ Loaded client profile from users collection');
        notifyListeners();
        return;
      }

      debugPrint(
        '⚠️ No profile found in either collection for user: ${_auth.currentUser!.uid}',
      );
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _userProfile = null;
      notifyListeners();
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (_auth.currentUser == null) throw 'User not authenticated';

    try {
      data['updatedAt'] = FieldValue.serverTimestamp();

      // Determine which collection to update based on current user profile
      String collectionName = 'users'; // default
      if (_userProfile != null) {
        String userType = _userProfile!['userType'] ?? 'client';
        collectionName = userType == 'lawyer' ? 'lawyers' : 'users';
      }

      await _firestore
          .collection(collectionName)
          .doc(_auth.currentUser!.uid)
          .update(data);
      await _loadUserProfile();
    } catch (e) {
      throw 'Failed to update profile. Please try again.';
    }
  }

  /// Get user type from profile
  UserType? getUserType() {
    if (_userProfile == null) return null;

    final userTypeString = _userProfile!['userType'] as String?;
    if (userTypeString == null) return null;

    try {
      return UserType.values.firstWhere((e) => e.name == userTypeString);
    } catch (e) {
      return null;
    }
  }

  /// Check if a user exists in Firebase Auth
  Future<bool> userExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      return false;
    }
  }

  /// Check if user profile exists in Firestore
  Future<bool> userProfileExists(String uid) async {
    try {
      // Check in lawyers collection first
      var doc = await _firestore.collection('lawyers').doc(uid).get();
      if (doc.exists) {
        return true;
      }

      // Check in users collection
      doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if user profile exists: $e');
      return false;
    }
  }

  /// Get user profile from Firestore by UID
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      // First try to find in lawyers collection
      var doc = await _firestore.collection('lawyers').doc(uid).get();
      if (doc.exists) {
        debugPrint('✅ Found lawyer profile in lawyers collection');
        return doc.data();
      }

      // If not found in lawyers, try users collection
      doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        debugPrint('✅ Found client profile in users collection');
        return doc.data();
      }

      debugPrint('⚠️ No profile found in either collection for UID: $uid');
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  /// Get available sign-in methods for an email
  Future<List<String>> getSignInMethods(String email) async {
    try {
      return await _auth.fetchSignInMethodsForEmail(email);
    } catch (e) {
      debugPrint('Error getting sign-in methods: $e');
      return [];
    }
  }

  /// Create a test user account for development (use only in development)
  Future<firebase_auth.UserCredential?> createTestUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      debugPrint('👤 Creating test user: $email');

      // Check if user already exists
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        debugPrint('⚠️ User already exists: $email');
        return null;
      }

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(name);

        // Create user profile in Firestore
        await _createUserProfileInBackground(
          user: userCredential.user!,
          name: name,
          userType: UserType.client,
          additionalData: {
            'phoneNumber': '+1 (555) 000-0000',
            'address': '123 Test Street, Test City, TC 12345',
          },
        );

        debugPrint('✅ Test user created successfully: $email');
        return userCredential;
      }

      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('❌ Error creating test user: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected error creating test user: $e');
      throw 'Failed to create test user. Please try again.';
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    debugPrint('🔥 Firebase Auth Exception: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address. Please sign up first.';
      case 'wrong-password':
        return 'Wrong password provided. Please check your password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'user-mismatch':
        return 'User mismatch error. Please try again.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      case 'credential-already-in-use':
        return 'This credential is already associated with another account.';
      default:
        debugPrint('🔥 Unhandled Firebase Auth Exception: ${e.code}');
        return 'Authentication failed: ${e.code}. Please try again.';
    }
  }

  /// Test Firebase connectivity and permissions
  Future<Map<String, dynamic>> testFirebaseConnectivity() async {
    final results = <String, dynamic>{};

    try {
      debugPrint('🧪 Testing Firebase connectivity...');

      // Test Firestore write permission
      try {
        final testDoc = _firestore.collection('_test').doc('connectivity');
        await testDoc.set({
          'timestamp': FieldValue.serverTimestamp(),
          'test': true,
        });
        debugPrint('✅ Firestore write test: PASSED');
        results['firestore_write'] = true;

        // Clean up test document
        await testDoc.delete();
        debugPrint('✅ Test document cleaned up');
      } catch (e) {
        debugPrint('❌ Firestore write test: FAILED - $e');
        results['firestore_write'] = false;
        results['firestore_error'] = e.toString();
      }

      // Test Firestore read permission
      try {
        final testDoc = await _firestore.collection('users').limit(1).get();
        debugPrint(
          '✅ Firestore read test: PASSED (${testDoc.docs.length} docs)',
        );
        results['firestore_read'] = true;
      } catch (e) {
        debugPrint('❌ Firestore read test: FAILED - $e');
        results['firestore_read'] = false;
        results['firestore_read_error'] = e.toString();
      }

      // Test Firebase Auth
      try {
        final currentUser = _auth.currentUser;
        debugPrint(
          '✅ Firebase Auth test: PASSED (current user: ${currentUser?.uid ?? 'none'})',
        );
        results['firebase_auth'] = true;
      } catch (e) {
        debugPrint('❌ Firebase Auth test: FAILED - $e');
        results['firebase_auth'] = false;
        results['firebase_auth_error'] = e.toString();
      }
    } catch (e) {
      debugPrint('❌ Firebase connectivity test failed: $e');
      results['overall'] = false;
      results['error'] = e.toString();
    }

    debugPrint('🧪 Firebase connectivity test results: $results');
    return results;
  }

  /// Check Firebase project configuration
  Future<Map<String, dynamic>> checkFirebaseConfig() async {
    final config = <String, dynamic>{};

    try {
      debugPrint('🔧 Checking Firebase configuration...');

      // Check Firebase Auth config
      try {
        final authConfig = _auth.app.options;
        config['project_id'] = authConfig.projectId;
        config['api_key'] = authConfig.apiKey;
        config['app_id'] = authConfig.appId;
        config['storage_bucket'] = authConfig.storageBucket;
        debugPrint('✅ Firebase Auth config: ${authConfig.projectId}');
      } catch (e) {
        debugPrint('❌ Firebase Auth config error: $e');
        config['auth_config_error'] = e.toString();
      }

      // Check Firestore config
      try {
        final firestoreConfig = _firestore.app.options;
        config['firestore_project_id'] = firestoreConfig.projectId;
        config['firestore_api_key'] = firestoreConfig.apiKey;
        debugPrint('✅ Firestore config: ${firestoreConfig.projectId}');
      } catch (e) {
        debugPrint('❌ Firestore config error: $e');
        config['firestore_config_error'] = e.toString();
      }

      // Check if configs match
      if (config['project_id'] != null &&
          config['firestore_project_id'] != null) {
        config['configs_match'] =
            config['project_id'] == config['firestore_project_id'];
        debugPrint('🔍 Configs match: ${config['configs_match']}');
      }
    } catch (e) {
      debugPrint('❌ Firebase config check failed: $e');
      config['error'] = e.toString();
    }

    debugPrint('🔧 Firebase config: $config');
    return config;
  }
}
