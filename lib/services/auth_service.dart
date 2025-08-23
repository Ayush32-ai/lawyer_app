import 'package:flutter/foundation.dart';
import '../models/user_type.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isAuthenticated = false;
  User? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;
  String? get userEmail => _currentUser?.email;

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Simple validation - in real app, you'd validate against a backend
      if (email.isNotEmpty && password.length >= 6) {
        _isAuthenticated = true;
        // Create a mock user for demo purposes
        _currentUser = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          name: 'Demo User',
          userType: UserType.client, // Default to client for login
          createdAt: DateTime.now(),
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Sign up with user details
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required UserType userType,
    String? phoneNumber,
    String? address,
    String? licenseNumber,
    String? specialty,
    int? yearsOfExperience,
    String? bio,
  }) async {
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Simple validation - in real app, you'd validate against a backend
      if (email.isNotEmpty && password.length >= 6 && name.isNotEmpty) {
        _isAuthenticated = true;
        _currentUser = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          name: name,
          userType: userType,
          createdAt: DateTime.now(),
          phoneNumber: phoneNumber,
          address: address,
          licenseNumber: licenseNumber,
          specialty: specialty,
          yearsOfExperience: yearsOfExperience,
          bio: bio,
          isVerified: userType == UserType.lawyer
              ? false
              : null, // Lawyers need verification
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  /// Check if user is already logged in (for app restart)
  Future<void> checkAuthStatus() async {
    // In a real app, you'd check secure storage or token validity
    // For demo purposes, we'll assume user is logged out on app restart
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
}
