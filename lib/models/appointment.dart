import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}

class Appointment {
  final String id;
  final String lawyerId;
  final String clientId;
  final DateTime dateTime;
  final AppointmentStatus status;
  final String description;
  final double rate;
  final String lawyerName;
  final String clientName;
  final String clientPhone;

  Appointment({
    required this.id,
    required this.lawyerId,
    required this.clientId,
    required this.dateTime,
    required this.status,
    required this.description,
    required this.rate,
    required this.lawyerName,
    required this.clientName,
    required this.clientPhone,
  });

  factory Appointment.fromFirestore(Map<String, dynamic> data, String id) {
    return Appointment(
      id: id,
      lawyerId: data['lawyerId'] ?? '',
      clientId: data['clientId'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => AppointmentStatus.pending,
      ),
      description: data['description'] ?? '',
      rate: (data['rate'] as num).toDouble(),
      lawyerName: data['lawyerName'] ?? '',
      clientName: data['clientName'] ?? '',
      clientPhone: data['clientPhone'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lawyerId': lawyerId,
      'clientId': clientId,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status.name,
      'description': description,
      'rate': rate,
      'lawyerName': lawyerName,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
