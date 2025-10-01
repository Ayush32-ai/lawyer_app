import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  Map<String, Map<String, dynamic>> _availability = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final doc = await _firestore
          .collection('lawyer_availability')
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        setState(() {
          _availability = Map<String, Map<String, dynamic>>.from(
            doc.data() ?? {},
          );
        });
      } else {
        // Initialize with default availability
        _initializeDefaultAvailability();
      }
    } catch (e) {
      debugPrint('Error loading availability: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeDefaultAvailability() {
    setState(() {
      for (int i = 0; i < 5; i++) {
        // Monday to Friday
        _availability[_days[i]] = {
          'enabled': true,
          'startTime': '09:00',
          'endTime': '17:00',
        };
      }
      for (int i = 5; i < 7; i++) {
        // Saturday and Sunday
        _availability[_days[i]] = {
          'enabled': false,
          'startTime': '09:00',
          'endTime': '17:00',
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Manage Availability',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _saveAvailability,
            child: Text(
              'Save',
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Header info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 32,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set Your Working Hours',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Clients will see your availability when booking appointments',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.blue[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Days list
                    Expanded(
                      child: ListView.builder(
                        itemCount: _days.length,
                        itemBuilder: (context, index) {
                          final day = _days[index];
                          final dayData =
                              _availability[day] ??
                              {
                                'enabled': false,
                                'startTime': '09:00',
                                'endTime': '17:00',
                              };

                          return _buildDayCard(day, dayData, index);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _enableWeekdays,
                            icon: const Icon(Icons.work),
                            label: const Text('Weekdays Only'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2196F3),
                              side: const BorderSide(color: Color(0xFF2196F3)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _enableAllDays,
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('All Days'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2196F3),
                              side: const BorderSide(color: Color(0xFF2196F3)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDayCard(String day, Map<String, dynamic> dayData, int index) {
    final isEnabled = dayData['enabled'] as bool;
    final startTime = dayData['startTime'] as String;
    final endTime = dayData['endTime'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Day header with toggle
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? const Color(0xFF2196F3).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      day.substring(0, 1),
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        color: isEnabled
                            ? const Color(0xFF2196F3)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    day,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? Colors.grey[800] : Colors.grey[500],
                    ),
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (value) {
                    setState(() {
                      _availability[day] = {...dayData, 'enabled': value};
                    });
                  },
                  activeColor: const Color(0xFF2196F3),
                ),
              ],
            ),

            // Time pickers (only show if enabled)
            if (isEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker('Start Time', startTime, (time) {
                      setState(() {
                        _availability[day] = {...dayData, 'startTime': time};
                      });
                    }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker('End Time', endTime, (time) {
                      setState(() {
                        _availability[day] = {...dayData, 'endTime': time};
                      });
                    }),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(
    String label,
    String currentTime,
    Function(String) onTimeChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showTimePicker(currentTime, onTimeChanged),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  currentTime,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTimePicker(String currentTime, Function(String) onTimeChanged) {
    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    showTimePicker(context: context, initialTime: initialTime).then((
      TimeOfDay? time,
    ) {
      if (time != null) {
        final timeString =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        onTimeChanged(timeString);
      }
    });
  }

  void _enableWeekdays() {
    setState(() {
      for (int i = 0; i < 5; i++) {
        // Monday to Friday
        _availability[_days[i]] = {
          'enabled': true,
          'startTime': '09:00',
          'endTime': '17:00',
        };
      }
      for (int i = 5; i < 7; i++) {
        // Saturday and Sunday
        _availability[_days[i]] = {
          'enabled': false,
          'startTime': '09:00',
          'endTime': '17:00',
        };
      }
    });
  }

  void _enableAllDays() {
    setState(() {
      for (final day in _days) {
        _availability[day] = {
          'enabled': true,
          'startTime': '09:00',
          'endTime': '17:00',
        };
      }
    });
  }

  Future<void> _saveAvailability() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore
          .collection('lawyer_availability')
          .doc(currentUserId)
          .set(_availability);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Availability saved successfully!',
              style: GoogleFonts.roboto(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving availability: $e',
              style: GoogleFonts.roboto(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

