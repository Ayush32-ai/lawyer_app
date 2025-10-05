import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A lightweight service that persists an authentication token securely on the
/// device using [FlutterSecureStorage].
///
/// When a user logs in successfully, store the Firebase ID token or a custom
/// session token with [saveAuthToken].  On app start, call [getAuthToken] to
/// determine if the user is still logged-in and should skip the welcome/login
/// screens.  When the user logs out explicitly, call [deleteAuthToken] to clear
/// the stored credentials.
class AuthPersistenceService {
  // Singleton boilerplate
  static final AuthPersistenceService _instance =
      AuthPersistenceService._internal();
  factory AuthPersistenceService() => _instance;
  AuthPersistenceService._internal();

  // Flutter secure storage instance
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Storage key
  static const String _kAuthTokenKey = 'auth_token';

  /// Persist the provided [token] securely on the device.
  Future<void> saveAuthToken(String token) async {
    try {
      await _secureStorage.write(key: _kAuthTokenKey, value: token);
      debugPrint('🔐 Auth token saved to secure storage');
    } catch (e) {
      debugPrint('❌ Failed to save auth token: $e');
    }
  }

  /// Returns the persisted auth token, or `null` if none is stored.
  Future<String?> getAuthToken() async {
    try {
      final token = await _secureStorage.read(key: _kAuthTokenKey);
      debugPrint('🔑 Auth token retrieved: ${token != null}');
      return token;
    } catch (e) {
      debugPrint('❌ Failed to read auth token: $e');
      return null;
    }
  }

  /// Removes the stored auth token from secure storage.
  Future<void> deleteAuthToken() async {
    try {
      await _secureStorage.delete(key: _kAuthTokenKey);
      debugPrint('🗑️  Auth token deleted from secure storage');
    } catch (e) {
      debugPrint('❌ Failed to delete auth token: $e');
    }
  }
}