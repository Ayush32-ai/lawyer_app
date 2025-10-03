import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../services/firebase_auth_service.dart';

class LawyerAppointmentsScreen extends StatelessWidget {
  const LawyerAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<FirebaseAuthService>(context, listen: false);
    final lawyerId = authService.currentUser?.uid;
    
    debugPrint('🔍 Checking appointments for lawyer: $lawyerId');

    if (lawyerId == null) {
      debugPrint('⚠️ No lawyer ID available - user not logged in');
      return const Center(child: Text('Please login to view appointments'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Appointments',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: Provider.of<AppointmentService>(context, listen: false)
            .getLawyerAppointments(lawyerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            debugPrint('⏳ Loading appointments from main collection...');
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('❌ Error loading appointments: ${snapshot.error}');
            return Center(
              child: Text(
                'Error loading appointments: ${snapshot.error}',
                style: GoogleFonts.roboto(color: Colors.red),
              ),
            );
          }

          var appointments = snapshot.data ?? [];
          debugPrint('📊 Found ${appointments.length} appointments in main collection');

          // If stream is empty (maybe writes go to lawyers/{id}/appointments),
          // try a one-time fetch of the lawyer subcollection.
          if (appointments.isEmpty) {
            debugPrint('ℹ️ Main collection empty, checking lawyer subcollection...');
            return FutureBuilder<List<Appointment>>(
              future: Provider.of<AppointmentService>(context, listen: false)
                  .getLawyerSubcollectionAppointments(lawyerId),
              builder: (context, subSnapshot) {
                if (subSnapshot.connectionState == ConnectionState.waiting) {
                  debugPrint('⏳ Loading from lawyer subcollection...');
                  return const Center(child: CircularProgressIndicator());
                }

                final subAppointments = subSnapshot.data ?? [];
                debugPrint('📊 Found ${subAppointments.length} appointments in lawyer subcollection');
                
                if (subAppointments.isEmpty) {
                  debugPrint('ℹ️ No appointments found in either collection');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No appointments yet',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                appointments = subAppointments;
                return _buildAppointmentsList(appointments);
              },
            );
          }
          return _buildAppointmentsList(appointments);
        },
      ),
    );
  }

  Widget _buildAppointmentsList(List<Appointment> appointments) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _AppointmentCard(appointment: appointment);
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const _AppointmentCard({required this.appointment});

  Color _getStatusColor() {
    switch (appointment.status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.completed:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Client: ${appointment.clientName}',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor()),
                  ),
                  child: Text(
                    appointment.status.toString().split('.').last,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Date: ${_formatDateTime(appointment.dateTime)}',
                  style: GoogleFonts.roboto(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.description, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Purpose: ${appointment.description}',
                    style: GoogleFonts.roboto(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Fee: \$${appointment.rate.toStringAsFixed(2)}',
                  style: GoogleFonts.roboto(color: Colors.grey[700]),
                ),
              ],
            ),
            if (appointment.status == AppointmentStatus.pending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(
                        context,
                        appointment.id,
                        AppointmentStatus.cancelled,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(
                        context,
                        appointment.id,
                        AppointmentStatus.confirmed,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _updateStatus(
    BuildContext context,
    String appointmentId,
    AppointmentStatus status,
  ) async {
    try {
      await Provider.of<AppointmentService>(context, listen: false)
          .updateAppointmentStatus(appointmentId, status);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Appointment ${status == AppointmentStatus.confirmed ? 'accepted' : 'declined'}',
            ),
            backgroundColor:
                status == AppointmentStatus.confirmed ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
