import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_type.dart';
import 'signup_client_screen.dart';
import 'signup_lawyer_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

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
              children: [
                // Back button
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                    size: 50,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Join LawyerFinder',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Choose your account type',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),

                const SizedBox(height: 48),

                // User type selection cards (scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildUserTypeCard(
                          context,
                          UserType.client,
                          Icons.person_outline,
                          'I need legal help',
                          'Find and connect with qualified lawyers',
                        ),

                        const SizedBox(height: 24),

                        _buildUserTypeCard(
                          context,
                          UserType.lawyer,
                          Icons.work_outline,
                          'I am a legal professional',
                          'Offer your services to potential clients',
                        ),

                        const SizedBox(height: 40),

                        // Terms and privacy
                        Text(
                          'By signing up, you agree to our Terms of Service\nand Privacy Policy',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(
    BuildContext context,
    UserType userType,
    IconData icon,
    String title,
    String description,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => userType == UserType.client
                ? const SignUpClientScreen()
                : const SignUpLawyerScreen(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: userType == UserType.client
                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                    : const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 40,
                color: userType == UserType.client
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF2196F3),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              description,
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Arrow
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
