import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/firebase_auth_service.dart';
import '../services/location_service.dart';
import 'dashboard_screen.dart';
import 'lawyer_dashboard_screen.dart';
import 'location_input_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Show splash for at least 3 seconds to display branding
    await Future.delayed(const Duration(seconds: 3));

    final firebaseAuthService =
        Provider.of<FirebaseAuthService>(context, listen: false);

    // If the user is already authenticated (Firebase keeps session by default),
    // forward them to the right screen instead of the welcome/login flow.
    if (firebaseAuthService.isAuthenticated &&
        firebaseAuthService.currentUser != null) {
      final uid = firebaseAuthService.currentUser!.uid;

      // Attempt to load the user profile to decide where to go next
      final userProfile = await firebaseAuthService.getUserProfile(uid);
      final userType = userProfile?['userType'] ?? 'client';

      // Check if the user already saved a location
      final hasSavedLocation = await LocationService.hasUserLocation(uid);

      if (hasSavedLocation) {
        final savedLocation = await LocationService.getUserLocation(uid);
        final address = savedLocation?['address'] ?? 'Unknown Location';

        if (!mounted) return;

        if (userType == 'lawyer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LawyerDashboardScreen(location: address),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(location: address),
            ),
          );
        }
        return; // exit after navigation
      } else {
        // No location yet, ask for it
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LocationInputScreen(),
          ),
        );
        return;
      }
    }

    // Not authenticated -> go to welcome screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.gavel,
                    size: 60,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 32),

                // App Name
                Text(
                  'LawyerFinder',
                  style: GoogleFonts.montserrat(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Tagline
                Text(
                  'Find a Lawyer Fast, Anytime, Anywhere',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                // Simple loading indicator
                Column(
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Loading...',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
