import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/appointment.dart';

class AppointmentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new appointment
  Future<String> createAppointment(Appointment appointment) async {
    try {
      debugPrint('📅 Creating appointment for lawyer: ${appointment.lawyerId}');

      // Create appointment document
      final docRef = await _firestore.collection('appointments').add(appointment.toFirestore());
      debugPrint('✅ Appointment booked successfully with ID: ${docRef.id}');

      // Update lawyer's appointments
      await _firestore.collection('lawyers').doc(appointment.lawyerId)
          .collection('appointments').doc(docRef.id)
          .set({
            'appointmentId': docRef.id,
            'dateTime': Timestamp.fromDate(appointment.dateTime),
            'status': appointment.status.name,
          });

      // Update client's appointments
      await _firestore.collection('users').doc(appointment.clientId)
          .collection('appointments').doc(docRef.id)
          .set({
            'appointmentId': docRef.id,
            'dateTime': Timestamp.fromDate(appointment.dateTime),
            'status': appointment.status.name,
          });

      notifyListeners();
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating appointment: $e');
      rethrow;
    }
  }

  /// Get appointments for a lawyer
  Stream<List<Appointment>> getLawyerAppointments(String lawyerId) {
    return _firestore
        .collection('appointments')
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get appointments for a client
  Stream<List<Appointment>> getClientAppointments(String clientId) {
    return _firestore
        .collection('appointments')
        .where('clientId', isEqualTo: clientId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Update appointment status
  Future<void> updateAppointmentStatus(
      String appointmentId, AppointmentStatus status) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Appointment status updated successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating appointment status: $e');
      rethrow;
    }
  }

  /// Cancel an appointment
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      await updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
      debugPrint('✅ Appointment cancelled successfully');
    } catch (e) {
      debugPrint('❌ Error cancelling appointment: $e');
      rethrow;
    }
  }
}
