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
      final firebase_auth.UserCredential result = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        await _loadUserProfile();
      }

      return result;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
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
      final firebase_auth.UserCredential result = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        // Update display name
        await result.user!.updateDisplayName(name);

        // Create user profile in Firestore
        await _createUserProfile(
          user: result.user!,
          name: name,
          userType: userType,
          additionalData: additionalData,
        );

        await _loadUserProfile();
      }

      return result;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Create user profile in Firestore
  Future<void> _createUserProfile({
    required firebase_auth.User user,
    required String name,
    required UserType userType,
    required Map<String, dynamic> additionalData,
  }) async {
    try {
      final profileData = {
        'uid': user.uid,
        'email': user.email,
        'name': name,
        'userType': userType.name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...additionalData,
      };

      await _firestore.collection('users').doc(user.uid).set(profileData);
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile() async {
    if (_auth.currentUser == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      if (doc.exists) {
        _userProfile = doc.data();
        notifyListeners();
      }
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
      await _firestore
          .collection('users')
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

  /// Handle Firebase Auth exceptions
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
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
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
