import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/firebase_auth_service.dart';
import '../services/location_service.dart';
import 'location_input_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'debug_database_screen.dart';
import 'package:flutter/foundation.dart';
import 'dashboard_screen.dart'; // Added import for DashboardScreen
import 'lawyer_dashboard_screen.dart'; // Added import for LawyerDashboardScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        debugPrint(
          '🔐 Attempting login with email: ${_emailController.text.trim()}',
        );

        final firebaseAuthService = Provider.of<FirebaseAuthService>(
          context,
          listen: false,
        );

        // Attempt login with Firebase directly
        final userCredential = await firebaseAuthService
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        if (userCredential != null && userCredential.user != null && mounted) {
          debugPrint(
            '✅ Login successful for user: ${userCredential.user!.email}',
          );

          // Get user profile to check user type
          final userProfile = await firebaseAuthService.getUserProfile(
            userCredential.user!.uid,
          );

          debugPrint('📊 User profile data: $userProfile');
          final userType = userProfile?['userType'] ?? 'client';
          debugPrint('👤 Detected user type: $userType');

          // Check if user has saved location
          final hasSavedLocation = await _checkUserHasSavedLocation(
            userCredential.user!.uid,
          );

          if (hasSavedLocation) {
            // User has saved location, get it and go to appropriate dashboard
            final savedLocation = await LocationService.getUserLocation(
              userCredential.user!.uid,
            );
            final locationAddress =
                savedLocation?['address'] ?? 'Unknown Location';

            debugPrint('🧭 Navigating to dashboard...');
            debugPrint('📍 Location: $locationAddress');
            debugPrint('👤 User type for routing: $userType');

            if (userType == 'lawyer') {
              debugPrint('✅ Routing to LawyerDashboardScreen');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LawyerDashboardScreen(location: locationAddress),
                ),
              );
            } else {
              debugPrint('✅ Routing to DashboardScreen (client)');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DashboardScreen(location: locationAddress),
                ),
              );
            }
          } else {
            // No saved location, go to location input screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LocationInputScreen(),
              ),
            );
          }
        } else {
          debugPrint('❌ Login failed: userCredential is null');
          if (mounted) {
            _showErrorDialog(
              'Login failed. Please check your credentials and try again.',
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Login error: $e');
        if (mounted) {
          _showErrorDialog(e.toString());
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Login Failed',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: GoogleFonts.roboto()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.roboto(color: const Color(0xFF2196F3)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createTestAccount() async {
    final firebaseAuthService = Provider.of<FirebaseAuthService>(
      context,
      listen: false,
    );

    try {
      debugPrint('🔐 Attempting to create test account: test@lawyerapp.com');
      final userCredential = await firebaseAuthService.createTestUser(
        email: 'test@lawyerapp.com',
        password: 'test123456',
        name: 'Test User',
      );

      if (userCredential != null && userCredential.user != null && mounted) {
        debugPrint(
          '✅ Test account created successfully for user: ${userCredential.user!.email}',
        );
        if (mounted) {
          _showSuccessDialog('Test account created successfully!');
        }
      } else {
        debugPrint('❌ Failed to create test account: userCredential is null');
        if (mounted) {
          _showErrorDialog('Failed to create test account. Please try again.');
        }
      }
    } catch (e) {
      debugPrint('❌ Error creating test account: $e');
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Success',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: GoogleFonts.roboto()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.roboto(color: const Color(0xFF2196F3)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testFirebaseConnectivity() async {
    try {
      final firebaseAuthService = Provider.of<FirebaseAuthService>(
        context,
        listen: false,
      );

      debugPrint('🧪 Testing Firebase connectivity...');
      final results = await firebaseAuthService.testFirebaseConnectivity();

      if (mounted) {
        _showConnectivityResults(results);
      }
    } catch (e) {
      debugPrint('❌ Error testing Firebase connectivity: $e');
      if (mounted) {
        _showErrorDialog('Failed to test Firebase connectivity: $e');
      }
    }
  }

  void _showConnectivityResults(Map<String, dynamic> results) {
    String message = 'Firebase Connectivity Test Results:\n\n';

    if (results['firestore_write'] == true) {
      message += '✅ Firestore Write: PASSED\n';
    } else {
      message += '❌ Firestore Write: FAILED\n';
      if (results['firestore_error'] != null) {
        message += '   Error: ${results['firestore_error']}\n';
      }
    }

    if (results['firestore_read'] == true) {
      message += '✅ Firestore Read: PASSED\n';
    } else {
      message += '❌ Firestore Read: FAILED\n';
      if (results['firestore_read_error'] != null) {
        message += '   Error: ${results['firestore_read_error']}\n';
      }
    }

    if (results['firebase_auth'] == true) {
      message += '✅ Firebase Auth: PASSED\n';
    } else {
      message += '❌ Firebase Auth: FAILED\n';
      if (results['firebase_auth_error'] != null) {
        message += '   Error: ${results['firebase_auth_error']}\n';
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Firebase Connectivity Test',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: GoogleFonts.roboto()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.roboto(color: const Color(0xFF2196F3)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testLogin() async {
    _emailController.text = 'test@lawyerapp.com';
    _passwordController.text = 'test123456';
    await _login();
  }

  Future<void> _checkFirebaseConfig() async {
    final firebaseAuthService = Provider.of<FirebaseAuthService>(
      context,
      listen: false,
    );

    try {
      debugPrint('🧪 Checking Firebase configuration...');
      final config = await firebaseAuthService.checkFirebaseConfig();

      if (mounted) {
        _showConfigResults(config);
      }
    } catch (e) {
      debugPrint('❌ Error checking Firebase config: $e');
      if (mounted) {
        _showErrorDialog('Failed to check Firebase config: $e');
      }
    }
  }

  void _showConfigResults(Map<String, dynamic> config) {
    String message = 'Firebase Configuration Check Results:\n\n';

    if (config['project_id'] != null) {
      message += '✅ Project ID: ${config['project_id']}\n';
    } else {
      message += '❌ Project ID: FAILED\n';
      if (config['auth_config_error'] != null) {
        message += '   Error: ${config['auth_config_error']}\n';
      }
    }

    if (config['api_key'] != null) {
      message +=
          '✅ API Key: ${config['api_key'].toString().substring(0, 10)}...\n';
    } else {
      message += '❌ API Key: FAILED\n';
    }

    if (config['app_id'] != null) {
      message += '✅ App ID: ${config['app_id']}\n';
    } else {
      message += '❌ App ID: FAILED\n';
    }

    if (config['storage_bucket'] != null) {
      message += '✅ Storage Bucket: ${config['storage_bucket']}\n';
    } else {
      message += '❌ Storage Bucket: FAILED\n';
    }

    if (config['firestore_project_id'] != null) {
      message += '✅ Firestore Project ID: ${config['firestore_project_id']}\n';
    } else {
      message += '❌ Firestore Project ID: FAILED\n';
      if (config['firestore_config_error'] != null) {
        message += '   Error: ${config['firestore_config_error']}\n';
      }
    }

    if (config['configs_match'] != null) {
      message +=
          '🔍 Configs Match: ${config['configs_match'] ? 'YES' : 'NO'}\n';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Firebase Configuration Check',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: GoogleFonts.roboto()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.roboto(color: const Color(0xFF2196F3)),
            ),
          ),
        ],
      ),
    );
  }

  // New method to check if user has saved location
  Future<bool> _checkUserHasSavedLocation(String userId) async {
    try {
      return await LocationService.hasUserLocation(userId);
    } catch (e) {
      debugPrint('❌ Error checking user location: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Logo and Title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.gavel,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'LawyerFinder',
                        style: GoogleFonts.montserrat(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect with legal experts',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Welcome Text
                Text(
                  'Welcome Back',
                  style: GoogleFonts.roboto(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your account',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 40),

                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2196F3),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF2196F3),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF2196F3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Demo Credentials Info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outlined,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Firebase Authentication',
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You need to create an account first or use existing Firebase credentials',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.blue[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Test Account: test@lawyerapp.com / test123456',
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: Colors.blue[500],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            // Development: Create Test Account Button
                            if (kDebugMode)
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: OutlinedButton(
                                  onPressed: () => _createTestAccount(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue[700],
                                    side: BorderSide(color: Colors.blue[300]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Create Test Account (Dev)',
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            if (kDebugMode) const SizedBox(height: 8),
                            // Development: Test Firebase Connectivity Button
                            if (kDebugMode)
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: OutlinedButton(
                                  onPressed: () => _testFirebaseConnectivity(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange[700],
                                    side: BorderSide(
                                      color: Colors.orange[300]!,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Test Firebase Connectivity (Dev)',
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            if (kDebugMode) const SizedBox(height: 8),
                            // Development: Test Login Button
                            if (kDebugMode)
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: OutlinedButton(
                                  onPressed: () => _testLogin(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green[700],
                                    side: BorderSide(color: Colors.green[300]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Test Login (Dev)',
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            if (kDebugMode) const SizedBox(height: 8),
                            // Development: Check Firebase Config Button
                            if (kDebugMode)
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: OutlinedButton(
                                  onPressed: () => _checkFirebaseConfig(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.purple[700],
                                    side: BorderSide(
                                      color: Colors.purple[300]!,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Check Firebase Config (Dev)',
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            if (kDebugMode) const SizedBox(height: 8),
                            // Development: Debug Database Button
                            if (kDebugMode)
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const DebugDatabaseScreen(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.orange[700],
                                    side: BorderSide(
                                      color: Colors.orange[300]!,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Debug Database (Dev)',
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: GoogleFonts.roboto(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.roboto(
                                color: const Color(0xFF2196F3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
