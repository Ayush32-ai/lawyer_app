import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/appointment.dart';
import 'document_service.dart';

class AppointmentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new appointment
  Future<String> createAppointment(Appointment appointment) async {
    try {
      final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
      debugPrint('📅 Creating appointment for lawyer: ${appointment.lawyerId}');
      debugPrint('🔐 Current user uid: ${currentUser?.uid}');

      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Ensure clientId matches authenticated user
      final payload = appointment.toFirestore();
      if (payload['clientId'] != currentUser.uid) {
        payload['clientId'] = currentUser.uid;
      }

      // Ensure status is 'pending' on create
      payload['status'] = AppointmentStatus.pending.name;

      // Ensure dateTime is a Timestamp
      if (payload['dateTime'] is! Timestamp && payload['dateTime'] is DateTime) {
        payload['dateTime'] = Timestamp.fromDate(payload['dateTime']);
      }

      // Ensure rate is numeric
      if (payload['rate'] is String) {
        final parsed = double.tryParse(payload['rate']);
        payload['rate'] = parsed ?? 0.0;
      }

      debugPrint('📤 Appointment payload: $payload');

      // Create appointment document
      final docRef = await _firestore.collection('appointments').add(payload);
      debugPrint('✅ Appointment booked successfully with ID: ${docRef.id}');

      // Verify the appointment was created in main collection
      final mainDoc = await _firestore.collection('appointments').doc(docRef.id).get();
      if (!mainDoc.exists) {
        debugPrint('⚠️ Appointment not found in main collection after creation!');
      } else {
        final data = mainDoc.data();
        debugPrint('✓ Appointment verified in main collection:');
        debugPrint('  - lawyerId: ${data?['lawyerId']}');
        debugPrint('  - clientId: ${data?['clientId']}');
        debugPrint('  - status: ${data?['status']}');
      }

      // Also create a lawyer_requests document so the lawyer's requests UI
      // receives the incoming client request.
      try {
        debugPrint('📝 Creating lawyer_requests document...');
        debugPrint('  - Lawyer ID: ${payload['lawyerId']}');
        debugPrint('  - Client ID: ${payload['clientId']}');
        
        final requestPayload = {
          'clientId': payload['clientId'],
          'lawyerId': payload['lawyerId'],
          'description': payload['description'] ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'clientName': payload['clientName'] ?? '',
          'clientPhone': payload['clientPhone'] ?? '',
          'lawyerName': payload['lawyerName'] ?? '',
          'appointmentId': docRef.id,
        };

        // Verify all required fields are present
        final requiredFields = ['clientId', 'lawyerId', 'status', 'createdAt'];
        final missingFields = requiredFields.where((field) => !requestPayload.containsKey(field));
        if (missingFields.isNotEmpty) {
          throw 'Missing required fields: ${missingFields.join(", ")}';
        }

        final requestDoc = await _firestore.collection('lawyer_requests').add(requestPayload);
        debugPrint('✅ lawyer_requests document created:');
        debugPrint('  - Request ID: ${requestDoc.id}');
        debugPrint('  - Appointment ID: ${docRef.id}');
        
        // Verify the document was created
        final createdRequest = await requestDoc.get();
        if (!createdRequest.exists) {
          throw 'Request document not found after creation';
        }
        debugPrint('✓ Request document verified in Firestore');
      } catch (e) {
        debugPrint('⚠️ Failed to create lawyer_requests doc: $e');
        debugPrint('⚠️ Stack trace: ${StackTrace.current}');
        // don't fail the whole flow because of this secondary write
      }      // Update lawyer's appointments
      // Save the full appointment payload under the lawyer's subcollection so
      // that security rules requiring fields like clientId, rate, etc. will pass.
      final lawyerPayload = Map<String, dynamic>.from(payload);
      lawyerPayload['appointmentId'] = docRef.id;
      await _firestore.collection('lawyers').doc(appointment.lawyerId)
          .collection('appointments').doc(docRef.id)
          .set(lawyerPayload);

      // Update client's appointments
      await _firestore.collection('users').doc(payload['clientId'])
          .collection('appointments').doc(docRef.id)
          .set({
            'appointmentId': docRef.id,
            'dateTime': payload['dateTime'],
            'status': payload['status'],
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
    debugPrint('🔍 Querying main appointments collection for lawyerId: $lawyerId');
    return _firestore
        .collection('appointments')
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('📊 Found ${snapshot.docs.length} appointments in main collection');
          return snapshot.docs
              .map((doc) {
                debugPrint('  - Appointment ${doc.id}: status=${doc.data()['status']}, dateTime=${doc.data()['dateTime']}');
                return Appointment.fromFirestore(doc.data(), doc.id);
              })
              .toList();
        });
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

  /// Get appointments from the lawyer's subcollection (one-time fetch)
  Future<List<Appointment>> getLawyerSubcollectionAppointments(String lawyerId) async {
    debugPrint('🔍 Checking lawyer subcollection for appointments...');
    try {
      // First verify the lawyer document exists
      final lawyerDoc = await _firestore.collection('lawyers').doc(lawyerId).get();
      if (!lawyerDoc.exists) {
        debugPrint('⚠️ Lawyer document does not exist for ID: $lawyerId');
        return [];
      }
      
      final snapshot = await _firestore
          .collection('lawyers')
          .doc(lawyerId)
          .collection('appointments')
          .orderBy('dateTime', descending: true)
          .get();

      debugPrint('📊 Found ${snapshot.docs.length} appointments in lawyer subcollection');
      
      // Log details of each appointment found
      for (final doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('  - Subcollection appointment ${doc.id}:');
        debugPrint('    * status: ${data['status']}');
        debugPrint('    * dateTime: ${data['dateTime']}');
        debugPrint('    * clientId: ${data['clientId']}');
      }

      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Error fetching lawyer subcollection appointments: $e');
      return [];
    }
  }

  /// Stream pending requests for a lawyer and include client's uploaded documents
  Stream<List<Map<String, dynamic>>> getLawyerRequestsWithDocuments(String lawyerId) {
    // Listen to appointments for this lawyer where status == 'pending'
    final appointmentsStream = _firestore
        .collection('appointments')
        .where('lawyerId', isEqualTo: lawyerId)
        .where('status', isEqualTo: AppointmentStatus.pending.name)
        .orderBy('dateTime', descending: true)
        .snapshots();

    return appointmentsStream.asyncMap((snapshot) async {
      final results = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final appt = Appointment.fromFirestore(doc.data(), doc.id);

        // Fetch client's documents (if any). We call the DocumentService which
        // stores documents in users/{uid}/documents and also a top-level documents collection.
        List<Map<String, dynamic>> clientDocs = [];
        try {
          clientDocs = await DocumentService.getUserDocuments(appt.clientId);
        } catch (e) {
          debugPrint('⚠️ Failed to load documents for client ${appt.clientId}: $e');
        }

        results.add({
          'appointment': appt,
          'documents': clientDocs,
          'appointmentId': doc.id,
        });
      }

      return results;
    });
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
