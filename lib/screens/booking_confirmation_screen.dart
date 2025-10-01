import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/lawyer.dart';
import '../models/appointment.dart';
import '../services/firebase_auth_service.dart';
import '../services/appointment_service.dart';
import 'document_upload_screen.dart';
import 'thank_you_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Lawyer lawyer;

  const BookingConfirmationScreen({super.key, required this.lawyer});

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String selectedType = 'Video Call';
  bool isConfirmed = false;

  final List<String> appointmentTypes = [
    'Video Call',
    'Phone Call',
    'In-Person',
  ];

  final List<TimeOfDay> availableTimes = [
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 16, minute: 0),
  ];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2196F3),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _confirmBooking() async {
    final authService = Provider.of<FirebaseAuthService>(context, listen: false);

    if (authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book an appointment')),
      );
      return;
    }

    setState(() {
      isConfirmed = true;
    });

    try {
      // Create appointment
      final appointmentId = await Provider.of<AppointmentService>(context, listen: false)
          .createAppointment(
        Appointment(
          id: '',  // Will be set by Firestore
          lawyerId: widget.lawyer.id,
          clientId: authService.currentUser!.uid,
          dateTime: DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          ),
          status: AppointmentStatus.pending,
          description: '$selectedType Consultation',
          rate: widget.lawyer.consultationFee,
          lawyerName: widget.lawyer.name,
          clientName: authService.userProfile?['name'] ?? 'Client',
          clientPhone: authService.userProfile?['phoneNumber'] ?? '',
        ),
      );

      debugPrint('✅ Appointment created with ID: $appointmentId');

      // Navigate after delay
      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ThankYouScreen(isBooking: true),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isConfirmed = false;
        });
        // Log the error but do not show an error SnackBar to the user
        debugPrint('❌ Error booking appointment: $e');
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    if (isConfirmed) {
      return Scaffold(
        backgroundColor: const Color(0xFF2196F3),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.check,
                  size: 50,
                  color: Color(0xFF2196F3),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Booking Confirmed!',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Processing your appointment...',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Book Appointment',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lawyer info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.blue[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lawyer.name,
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            widget.lawyer.specialty,
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.blue[600],
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber[600],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.lawyer.rating} (${widget.lawyer.reviewCount} reviews)',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Date selection
              Text(
                'Select Date',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(selectedDate),
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

              const SizedBox(height: 24),

              // Time selection
              Text(
                'Select Time',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: availableTimes.length,
                itemBuilder: (context, index) {
                  final time = availableTimes[index];
                  final isSelected = time == selectedTime;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTime = time;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2196F3)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2196F3)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _formatTime(time),
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Appointment type
              Text(
                'Appointment Type',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),

              Column(
                children: appointmentTypes.map((type) {
                  final isSelected = type == selectedType;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedType = type;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[50] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2196F3)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            type == 'Video Call'
                                ? Icons.video_call
                                : type == 'Phone Call'
                                ? Icons.phone
                                : Icons.location_on,
                            color: isSelected
                                ? const Color(0xFF2196F3)
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            type,
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: isSelected
                                  ? const Color(0xFF2196F3)
                                  : Colors.grey[800],
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF2196F3),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointment Summary',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Date', _formatDate(selectedDate)),
                    _buildSummaryRow('Time', _formatTime(selectedTime)),
                    _buildSummaryRow('Type', selectedType),
                    _buildSummaryRow('Lawyer', widget.lawyer.name),
                    _buildSummaryRow(
                      'Fee',
                      widget.lawyer.consultationFee == 0
                          ? 'Free consultation'
                          : '\$${widget.lawyer.consultationFee.toInt()}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Upload documents prompt
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: Colors.orange[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload documents before the session?',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[800],
                            ),
                          ),
                          Text(
                            'Share relevant documents in advance',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DocumentUploadScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Upload',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _confirmBooking,
                  child: Text(
                    'Confirm Appointment',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.blue[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}






