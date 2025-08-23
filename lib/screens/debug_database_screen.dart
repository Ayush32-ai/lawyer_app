import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_init_service.dart';
import '../services/firestore_service.dart';

class DebugDatabaseScreen extends StatefulWidget {
  const DebugDatabaseScreen({super.key});

  @override
  State<DebugDatabaseScreen> createState() => _DebugDatabaseScreenState();
}

class _DebugDatabaseScreenState extends State<DebugDatabaseScreen> {
  Map<String, int> _stats = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await DatabaseInitService.getDatabaseStats();
      setState(() => _stats = stats);
    } catch (e) {
      _showError('Failed to load stats: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeDatabase() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseInitService.initializeDatabase();
      _showSuccess('Database initialized successfully!');
      await _loadStats();
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
        await _loadStats();
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
                              onPressed: _loadStats,
                              icon: const Icon(Icons.refresh),
                              label: Text(
                                'Refresh Stats',
                                style: GoogleFonts.roboto(),
                              ),
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
                            '• Refresh Stats: Updates the document counts\n\n'
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

