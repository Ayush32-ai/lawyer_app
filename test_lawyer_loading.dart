import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/models/lawyer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Test loading lawyers from Firestore
  print('🔍 Testing lawyer loading from Firestore...');

  try {
    final firestore = FirebaseFirestore.instance;

    // Get lawyers collection
    final lawyersSnapshot = await firestore.collection('lawyers').get();
    print('📊 Found ${lawyersSnapshot.docs.length} lawyers in collection');

    for (var doc in lawyersSnapshot.docs) {
      print('👤 Lawyer ID: ${doc.id}');
      print('📄 Data: ${doc.data()}');

      try {
        final lawyer = Lawyer.fromFirestore(doc.data(), doc.id);
        print('✅ Parsed lawyer: ${lawyer.name} - ${lawyer.specialty}');
      } catch (e) {
        print('❌ Error parsing lawyer: $e');
      }
      print('---');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

