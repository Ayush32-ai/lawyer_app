import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/favorites_service.dart';
import '../models/lawyer.dart';
import 'lawyer_profile_screen.dart';

class RecentSavedScreen extends StatefulWidget {
  const RecentSavedScreen({super.key});

  @override
  State<RecentSavedScreen> createState() => _RecentSavedScreenState();
}

class _RecentSavedScreenState extends State<RecentSavedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize mock data if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final favoritesService = Provider.of<FavoritesService>(
        context,
        listen: false,
      );
      favoritesService.initializeMockData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Recent & Saved',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.roboto(fontWeight: FontWeight.w500),
          tabs: const [
            Tab(icon: Icon(Icons.history), text: 'Recent'),
            Tab(icon: Icon(Icons.favorite), text: 'Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildRecentTab(), _buildSavedTab()],
      ),
    );
  }

  Widget _buildRecentTab() {
    return Consumer<FavoritesService>(
      builder: (context, favoritesService, child) {
        final recentLawyers = favoritesService.recentlyViewed;

        if (recentLawyers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            title: 'No Recent Views',
            subtitle: 'Lawyers you view will appear here for quick access',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Simulate refresh
            await Future.delayed(const Duration(seconds: 1));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recentLawyers.length,
            itemBuilder: (context, index) {
              final lawyer = recentLawyers[index];
              return _buildLawyerCard(
                lawyer,
                isRecent: true,
                favoritesService: favoritesService,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSavedTab() {
    return Consumer<FavoritesService>(
      builder: (context, favoritesService, child) {
        final savedLawyers = favoritesService.savedLawyers;

        if (savedLawyers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border,
            title: 'No Saved Lawyers',
            subtitle: 'Save lawyers you like for easy access later',
          );
        }

        return Column(
          children: [
            // Clear all button
            if (savedLawyers.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () => _showClearSavedDialog(favoritesService),
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: Text('Clear All Saved', style: GoogleFonts.roboto()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

            // Saved lawyers list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Simulate refresh
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: savedLawyers.length,
                  itemBuilder: (context, index) {
                    final lawyer = savedLawyers[index];
                    return _buildLawyerCard(
                      lawyer,
                      isRecent: false,
                      favoritesService: favoritesService,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLawyerCard(
    Lawyer lawyer, {
    required bool isRecent,
    required FavoritesService favoritesService,
  }) {
    final isSaved = favoritesService.isSaved(lawyer.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          // Add to recently viewed when opening profile
          favoritesService.addToRecentlyViewed(lawyer);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LawyerProfileScreen(lawyer: lawyer),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Profile picture
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(Icons.person, size: 30, color: Colors.blue[600]),
              ),

              const SizedBox(width: 16),

              // Lawyer info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lawyer.name,
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isRecent)
                          Icon(
                            Icons.history,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      lawyer.specialty,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        // Rating
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber[600],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lawyer.rating.toString(),
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        // Experience
                        Text(
                          '${lawyer.experienceYears} yrs exp',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),

                        const Spacer(),

                        // Consultation fee
                        Text(
                          lawyer.consultationFee == 0
                              ? 'Free'
                              : '\$${lawyer.consultationFee.toInt()}',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Save/Unsave button
              IconButton(
                onPressed: () => favoritesService.toggleSave(lawyer),
                icon: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  color: isSaved ? Colors.red : Colors.grey[400],
                  size: 24,
                ),
                tooltip: isSaved ? 'Remove from saved' : 'Save lawyer',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(icon, size: 50, color: Colors.grey[400]),
            ),

            const SizedBox(height: 24),

            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showClearSavedDialog(FavoritesService favoritesService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Saved Lawyers',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove all saved lawyers? This action cannot be undone.',
          style: GoogleFonts.roboto(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.roboto(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              favoritesService.clearSavedLawyers();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'All saved lawyers cleared',
                    style: GoogleFonts.roboto(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text(
              'Clear All',
              style: GoogleFonts.roboto(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

