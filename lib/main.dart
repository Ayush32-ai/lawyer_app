import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/favorites_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_service.dart';
import 'services/database_init_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    debugPrint('🔥 Initializing Firebase...');
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
    // Continue with app initialization even if Firebase fails
  }

  // Initialize Firestore Database with sample data
  try {
    await DatabaseInitService.initializeDatabase();
    debugPrint('✅ Database initialization complete');
  } catch (e) {
    debugPrint('❌ Database initialization failed: $e');
  }

  // Create test user for development (optional)
  try {
    await DatabaseInitService.createTestUser();
    debugPrint('✅ Test user creation complete');
  } catch (e) {
    debugPrint('❌ Test user creation failed: $e');
  }

  // Create test user in Firebase Auth
  try {
    final firebaseAuthService = FirebaseAuthService();
    await firebaseAuthService.createTestUser(
      email: 'test@lawyerapp.com',
      password: 'test123456',
      name: 'Test User',
    );
    debugPrint('✅ Test user created in Firebase Auth');
  } catch (e) {
    debugPrint('⚠️ Could not create test user: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => NotificationService()),
        ChangeNotifierProvider(create: (context) => FavoritesService()),
        ChangeNotifierProvider(create: (context) => FirebaseAuthService()),
        ChangeNotifierProvider(create: (context) => FirestoreService()),
      ],
      child: const LawyerApp(),
    ),
  );
}

class LawyerApp extends StatelessWidget {
  const LawyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LawyerFinder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2196F3),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2196F3),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: const BorderSide(color: Color(0xFF2196F3)),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
