import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_init_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/document_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/production_database_service.dart';

class DebugDatabaseScreen extends StatefulWidget {
  const DebugDatabaseScreen({super.key});

  @override
  State<DebugDatabaseScreen> createState() => _DebugDatabaseScreenState();
}

class _DebugDatabaseScreenState extends State<DebugDatabaseScreen> {
  Map<String, int> _stats = {};
  bool _isLoading = false;

  // New data for location and documents
  Map<String, dynamic>? _userLocation;
  List<Map<String, dynamic>> _userDocuments = [];
  Map<String, dynamic>? _documentStats;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      // Load database stats
      final stats = await DatabaseInitService.getDatabaseStats();
      setState(() => _stats = stats);

      // Load user-specific data
      await _loadUserData();
    } catch (e) {
      _showError('Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final firebaseAuthService = Provider.of<FirebaseAuthService>(
        context,
        listen: false,
      );
      final currentUser = firebaseAuthService.currentUser;

      if (currentUser != null) {
        // Load user location
        final location = await LocationService.getUserLocation(currentUser.uid);
        setState(() => _userLocation = location);

        // Load user documents
        final documents = await DocumentService.getUserDocuments(
          currentUser.uid,
        );
        setState(() => _userDocuments = documents);

        // Load document stats
        final stats = await DocumentService.getUserDocumentStats(
          currentUser.uid,
        );
        setState(() => _documentStats = stats);
      }
    } catch (e) {
      debugPrint('Could not load user data: $e');
    }
  }

  Future<void> _initializeDatabase() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseInitService.initializeDatabase();
      _showSuccess('Database initialized successfully!');
      await _loadAllData(); // Refresh all data after initialization
    } catch (e) {
      _showError('Failed to initialize database: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearDatabase() async {
    final confirmed = await _showConfirmDialog(
      'Clear Database',
      'Are you sure you want to clear all data? This action cannot be undone.',
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await DatabaseInitService.clearAllData();
        _showSuccess('Database cleared successfully!');
        await _loadAllData(); // Refresh all data after clearing
      } catch (e) {
        _showError('Failed to clear database: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testFirestore() async {
    setState(() => _isLoading = true);
    try {
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );
      final lawyers = await firestoreService.getLawyers();
      _showSuccess(
        'Firestore test successful! Found ${lawyers.length} lawyers.',
      );
    } catch (e) {
      _showError('Firestore test failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testLocationService() async {
    setState(() => _isLoading = true);
    try {
      final firebaseAuthService = Provider.of<FirebaseAuthService>(
        context,
        listen: false,
      );
      final currentUser = firebaseAuthService.currentUser;

      if (currentUser != null) {
        // Test saving a sample location
        await LocationService.saveUserLocation(
          address: 'Test Location - Debug Screen',
          latitude: 40.7128,
          longitude: -74.0060,
          additionalData: {'source': 'debug_test'},
        );

        // Reload user data
        await _loadUserData();

        _showSuccess('Location service test successful! Test location saved.');
      } else {
        _showError('No user logged in to test location service.');
      }
    } catch (e) {
      _showError('Location service test failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testDocumentService() async {
    setState(() => _isLoading = true);
    try {
      final firebaseAuthService = Provider.of<FirebaseAuthService>(
        context,
        listen: false,
      );
      final currentUser = firebaseAuthService.currentUser;

      if (currentUser != null) {
        // Get document stats to test the service
        final stats = await DocumentService.getUserDocumentStats(
          currentUser.uid,
        );
        _showSuccess(
          'Document service test successful! User has ${stats['totalDocuments']} documents.',
        );

        // Reload user data
        await _loadUserData();
      } else {
        _showError('No user logged in to test document service.');
      }
    } catch (e) {
      _showError('Document service test failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeProductionDatabase() async {
    setState(() => _isLoading = true);
    try {
      await ProductionDatabaseService.initializeProductionDatabase();
      _showSuccess('Production database initialized successfully!');
      await _loadAllData(); // Refresh all data after initialization
    } catch (e) {
      _showError('Failed to initialize production database: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyProductionHealth() async {
    setState(() => _isLoading = true);
    try {
      final health = await ProductionDatabaseService.verifyProductionHealth();
      _showSuccess(
        'Production health check completed: ${health['overallStatus']}',
      );
      await _loadAllData(); // Refresh all data after health check
    } catch (e) {
      _showError('Failed to verify production health: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cleanupTemplates() async {
    final confirmed = await _showConfirmDialog(
      'Cleanup Templates',
      'Are you sure you want to remove template documents? This action cannot be undone.',
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ProductionDatabaseService.cleanupTemplates();
        _showSuccess('Template documents cleaned up successfully!');
        await _loadAllData(); // Refresh all data after cleanup
      } catch (e) {
        _showError('Failed to cleanup templates: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        content: Text(content, style: GoogleFonts.roboto()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.roboto()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Confirm',
              style: GoogleFonts.roboto(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Database Debug',
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Database Stats Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics, color: Colors.blue[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Database Statistics',
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_stats.isEmpty)
                            Text(
                              'No statistics available',
                              style: GoogleFonts.roboto(
                                color: Colors.grey[600],
                              ),
                            )
                          else
                            ..._stats.entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${entry.key.capitalize()}:',
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '${entry.value}',
                                        style: GoogleFonts.roboto(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _loadAllData, // Refresh all data
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                'Refresh All Data',
                                style: GoogleFonts.roboto(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // User Location Card
                  if (_userLocation != null)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.purple[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'User Location',
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Latitude: ${_userLocation!['latitude']}',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Longitude: ${_userLocation!['longitude']}',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Timestamp: ${_userLocation!['timestamp']}',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // User Documents Card
                  if (_userDocuments.isNotEmpty)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description,
                                  color: Colors.teal[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'User Documents',
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._userDocuments.map(
                              (doc) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '📄 ${doc['fileName'] ?? 'Unknown'}',
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    Text(
                                      'Type: ${doc['documentType'] ?? 'Unknown'} | Size: ${doc['fileSize'] ?? 'Unknown'} bytes',
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (doc['description'] != null &&
                                        doc['description']
                                            .toString()
                                            .isNotEmpty)
                                      Text(
                                        'Description: ${doc['description']}',
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Document Stats Card
                  if (_documentStats != null)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bar_chart,
                                  color: Colors.orange[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Document Statistics',
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Total Documents: ${_documentStats!['totalDocuments']}',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              'Total Size: ${_documentStats!['totalSize']} bytes',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Database Actions Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.settings, color: Colors.orange[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Database Actions',
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Initialize Database Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _initializeDatabase,
                              icon: const Icon(Icons.upload),
                              label: Text(
                                'Initialize Database',
                                style: GoogleFonts.roboto(),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Test Firestore Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _testFirestore,
                              icon: const Icon(Icons.science),
                              label: Text(
                                'Test Firestore Connection',
                                style: GoogleFonts.roboto(),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Test Location Service Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _testLocationService,
                              icon: const Icon(Icons.location_on),
                              label: Text(
                                'Test Location Service',
                                style: GoogleFonts.roboto(),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Test Document Service Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _testDocumentService,
                              icon: const Icon(Icons.description),
                              label: Text(
                                'Test Document Service',
                                style: GoogleFonts.roboto(),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Production Database Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🚀 Production Database Tools',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber[800],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Initialize Production Database Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _initializeProductionDatabase,
                                    icon: const Icon(Icons.rocket_launch),
                                    label: Text(
                                      'Initialize Production DB',
                                      style: GoogleFonts.roboto(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber[600],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Verify Production Health Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _verifyProductionHealth,
                                    icon: const Icon(Icons.health_and_safety),
                                    label: Text(
                                      'Verify Production Health',
                                      style: GoogleFonts.roboto(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Cleanup Templates Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _cleanupTemplates,
                                    icon: const Icon(Icons.cleaning_services),
                                    label: Text(
                                      'Cleanup Templates',
                                      style: GoogleFonts.roboto(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange[600],
                                      side: BorderSide(
                                        color: Colors.orange[300]!,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Clear Database Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _clearDatabase,
                              icon: const Icon(Icons.delete_forever),
                              label: Text(
                                'Clear All Data',
                                style: GoogleFonts.roboto(),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.amber[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Database Information',
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This debug screen helps you manage your Firestore database:\n\n'
                            '• Initialize Database: Adds sample lawyers data to Firestore\n'
                            '• Test Connection: Verifies Firestore is working properly\n'
                            '• Clear Data: Removes all data from Firestore\n'
                            '• Refresh Stats: Updates the document counts\n'
                            '• View User Location: Displays the last known location of the current user\n'
                            '• View User Documents: Lists all documents created by the current user\n'
                            '• View Document Stats: Shows total document count and size for the current user\n\n'
                            '🚀 Production Database Tools:\n'
                            '• Initialize Production DB: Sets up production database with proper structure\n'
                            '• Verify Production Health: Checks if production database is working correctly\n'
                            '• Cleanup Templates: Removes template documents after initialization\n\n'
                            'Use this screen during development to set up and manage your database.',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
