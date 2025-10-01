import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class DocumentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final firebase_auth.FirebaseAuth _auth =
      firebase_auth.FirebaseAuth.instance;

  /// Check if Firebase Storage is available and accessible
  static Future<bool> isStorageAvailable() async {
    try {
      // Test with a simple write operation instead of listAll()
      final testRef = _storage.ref().child('_test_availability');
      await testRef.putString('test', format: PutStringFormat.raw);
      await testRef.delete(); // Clean up
      return true;
    } catch (e) {
      debugPrint('❌ Firebase Storage not accessible: $e');
      return false;
    }
  }

  /// Initialize storage structure for a user
  static Future<void> initializeUserStorage(String userId) async {
    try {
      debugPrint('🔧 Initializing storage structure for user: $userId');

      // Create a test file reference to ensure the path exists
      final testRef = _storage
          .ref()
          .child('documents')
          .child(userId)
          .child('.test');

      // This will create the directory structure
      await testRef.putString('test', format: PutStringFormat.raw);
      await testRef.delete(); // Clean up test file

      debugPrint('✅ Storage structure initialized for user: $userId');
    } catch (e) {
      debugPrint('❌ Error initializing storage structure: $e');
      // Don't throw here, just log the error
    }
  }

  /// Ensure Firestore collections exist
  static Future<void> ensureCollectionsExist(String userId) async {
    try {
      debugPrint('🔧 Ensuring Firestore collections exist for user: $userId');

      // Create user document if it doesn't exist
      final userDoc = _firestore.collection('users').doc(userId);
      final userDocSnapshot = await userDoc.get();

      if (!userDocSnapshot.exists) {
        await userDoc.set({
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ User document created');
      }

      // Create a test document in the user's documents collection
      final testDocRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('documents')
          .doc('.test');

      await testDocRef.set({
        'test': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clean up test document
      await testDocRef.delete();

      debugPrint('✅ Collections verified for user: $userId');
    } catch (e) {
      debugPrint('❌ Error ensuring collections exist: $e');
      // Don't throw here, just log the error
    }
  }

  /// Upload document to Firebase Storage and save metadata to Firestore
  static Future<Map<String, dynamic>> uploadDocument({
    required String filePath,
    required String fileName,
    required String documentType,
    String? description,
    String? userId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('📄 Starting document upload: $fileName');

      // Ensure user is authenticated and get fresh token
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated. Please log in again.';
      }

      // Force refresh the ID token to ensure it's valid
      try {
        await currentUser.getIdToken(true); // Force refresh
        debugPrint('✅ Authentication token refreshed successfully');
      } catch (e) {
        debugPrint('❌ Failed to refresh authentication token: $e');
        throw 'Authentication token expired. Please log in again.';
      }

      final uid = userId ?? currentUser.uid;
      debugPrint('🔐 Using authenticated user: $uid');

      // Validate Firebase Storage is available
      try {
        await _storage.ref().listAll();
        debugPrint('✅ Firebase Storage is accessible');
      } catch (e) {
        debugPrint('❌ Firebase Storage not accessible: $e');
        throw 'Firebase Storage is not available. Please check your configuration.';
      }

      // Initialize storage bucket if needed
      await initializeStorageBucket();

      // Test storage access
      final storageTestPassed = await testStorageAccess();
      if (!storageTestPassed) {
        throw 'Firebase Storage test failed. Please check your configuration and try again.';
      }

      // Initialize storage structure for the user
      await initializeUserStorage(uid);

      // Ensure Firestore collections exist
      await ensureCollectionsExist(uid);

      final file = File(filePath);
      if (!await file.exists()) {
        throw 'File does not exist: $filePath';
      }

      // Get file size and extension
      final fileSize = await file.length();
      final fileExtension = path.extension(fileName).toLowerCase();

      // Validate file type
      if (!_isValidFileType(fileExtension)) {
        throw 'Invalid file type: $fileExtension. Allowed: PDF, DOC, DOCX, JPG, PNG';
      }

      // Validate file size (max 50MB)
      if (fileSize > 50 * 1024 * 1024) {
        throw 'File size too large. Maximum allowed: 50MB';
      }

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${uid}_${timestamp}_$fileName';

      // Create storage reference with proper error handling
      final storageRef = _storage
          .ref()
          .child('documents')
          .child(uid)
          .child(uniqueFileName);

      debugPrint('📤 Uploading to Firebase Storage: $uniqueFileName');
      debugPrint('📁 Storage path: ${storageRef.fullPath}');

      // Get fresh authentication token for storage operations
      String idToken;
      try {
        final token = await currentUser.getIdToken();
        if (token == null) {
          throw 'Failed to get authentication token';
        }
        idToken = token;
        debugPrint('✅ Got authentication token for storage operations');
      } catch (e) {
        debugPrint('❌ Failed to get authentication token: $e');
        throw 'Failed to get authentication token. Please log in again.';
      }

      // Upload to Firebase Storage with proper error handling and auth token
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(
          contentType: _getMimeType(fileExtension),
          customMetadata: {
            'originalName': fileName,
            'uploadedBy': uid,
            'documentType': documentType,
            'uploadedAt': DateTime.now().toIso8601String(),
            'authToken': idToken, // Include auth token in metadata
          },
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint(
          '📤 Upload progress: ${(progress * 100).toStringAsFixed(1)}%',
        );
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Verify upload was successful
      if (snapshot.state != TaskState.success) {
        throw 'Upload failed. State: ${snapshot.state}';
      }

      // Get download URL
      String downloadUrl;
      try {
        downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('✅ Download URL obtained: $downloadUrl');
      } catch (e) {
        debugPrint('❌ Error getting download URL: $e');
        throw 'Upload completed but could not get download URL. Please try again.';
      }

      debugPrint(
        '✅ Document uploaded successfully. Download URL: $downloadUrl',
      );

      // Save metadata to Firestore
      final documentData = {
        'userId': uid,
        'fileName': fileName,
        'uniqueFileName': uniqueFileName,
        'documentType': documentType,
        'description': description,
        'fileSize': fileSize,
        'fileExtension': fileExtension,
        'downloadUrl': downloadUrl,
        'storagePath': snapshot.ref.fullPath,
        'uploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'uploaded',
        ...?additionalData,
      };

      // Save to user's documents collection
      final docRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('documents')
          .add(documentData);

      // Also save to main documents collection for global access
      await _firestore.collection('documents').doc(docRef.id).set(documentData);

      debugPrint(
        '✅ Document metadata saved to Firestore with ID: ${docRef.id}',
      );

      return {
        'id': docRef.id,
        'downloadUrl': downloadUrl,
        'fileName': fileName,
        'documentType': documentType,
        'fileSize': fileSize,
        'uploadedAt': DateTime.now().toIso8601String(),
        'storagePath': snapshot.ref.fullPath,
      };
    } catch (e) {
      debugPrint('❌ Error uploading document: $e');

      // Provide more specific error messages
      if (e.toString().contains('firebase_storage/object-not-found')) {
        throw 'Firebase Storage bucket not found. Please check your Firebase configuration.';
      } else if (e.toString().contains('firebase_storage/unauthorized')) {
        throw 'Access denied to Firebase Storage. Please check your security rules.';
      } else if (e.toString().contains('firebase_storage/quota-exceeded')) {
        throw 'Storage quota exceeded. Please contact support.';
      } else if (e.toString().contains('firebase_storage/unauthenticated')) {
        throw 'Authentication required. Please log in again.';
      }

      rethrow;
    }
  }

  /// Get user's documents from Firestore
  static Future<List<Map<String, dynamic>>> getUserDocuments(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('documents')
          .orderBy('uploadedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting user documents: $e');
      return [];
    }
  }

  /// Get document by ID
  static Future<Map<String, dynamic>?> getDocument(String documentId) async {
    try {
      final doc = await _firestore
          .collection('documents')
          .doc(documentId)
          .get();

      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting document: $e');
      return null;
    }
  }

  /// Delete document from Firebase Storage and Firestore
  static Future<void> deleteDocument(String documentId, String userId) async {
    try {
      debugPrint('🗑️ Deleting document: $documentId');

      // Get document data first
      final document = await getDocument(documentId);
      if (document == null) {
        throw 'Document not found';
      }

      // Check if user owns the document
      if (document['userId'] != userId) {
        throw 'Unauthorized to delete this document';
      }

      // Delete from Firebase Storage
      try {
        final storageRef = _storage.ref(document['storagePath']);
        await storageRef.delete();
        debugPrint('✅ Document deleted from Firebase Storage');
      } catch (e) {
        debugPrint('⚠️ Could not delete from Storage: $e');
      }

      // Delete from Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('documents')
          .doc(documentId)
          .delete();

      await _firestore.collection('documents').doc(documentId).delete();

      debugPrint('✅ Document deleted from Firestore');
    } catch (e) {
      debugPrint('❌ Error deleting document: $e');
      rethrow;
    }
  }

  /// Update document metadata
  static Future<void> updateDocumentMetadata({
    required String documentId,
    required String userId,
    String? description,
    String? documentType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('✏️ Updating document metadata: $documentId');

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (description != null) updateData['description'] = description;
      if (documentType != null) updateData['documentType'] = documentType;
      if (additionalData != null) updateData.addAll(additionalData);

      // Update in both collections
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('documents')
          .doc(documentId)
          .update(updateData);

      await _firestore
          .collection('documents')
          .doc(documentId)
          .update(updateData);

      debugPrint('✅ Document metadata updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating document metadata: $e');
      rethrow;
    }
  }

  /// Get document statistics for a user
  static Future<Map<String, dynamic>> getUserDocumentStats(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('documents')
          .get();

      final documents = querySnapshot.docs;
      final totalDocuments = documents.length;
      final totalSize = documents.fold<int>(
        0,
        (sum, doc) => sum + ((doc.data()['fileSize'] as int?) ?? 0),
      );

      // Group by document type
      final typeCounts = <String, int>{};
      for (final doc in documents) {
        final type = doc.data()['documentType'] ?? 'Unknown';
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }

      return {
        'totalDocuments': totalDocuments,
        'totalSize': totalSize,
        'typeCounts': typeCounts,
        'lastUploaded': documents.isNotEmpty
            ? documents.first.data()['uploadedAt']
            : null,
      };
    } catch (e) {
      debugPrint('❌ Error getting document stats: $e');
      return {
        'totalDocuments': 0,
        'totalSize': 0,
        'typeCounts': {},
        'lastUploaded': null,
      };
    }
  }

  /// Validate file type
  static bool _isValidFileType(String extension) {
    const allowedExtensions = [
      '.pdf',
      '.doc',
      '.docx',
      '.jpg',
      '.jpeg',
      '.png',
    ];
    return allowedExtensions.contains(extension.toLowerCase());
  }

  /// Get MIME type for file extension
  static String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Check Firebase project configuration
  static Future<Map<String, dynamic>> checkFirebaseConfiguration() async {
    final results = <String, dynamic>{};

    try {
      // Check project status first
      final projectStatus = await checkProjectStatus();
      results.addAll(projectStatus);

      // Check Firebase Storage
      try {
        await _storage.ref().listAll();
        results['storage'] = {
          'status': 'success',
          'message': 'Firebase Storage is accessible',
        };
      } catch (e) {
        results['storage'] = {
          'status': 'error',
          'message': 'Firebase Storage error: $e',
        };
      }

      // Check Firestore
      try {
        await _firestore.collection('_test').doc('_test').get();
        results['firestore'] = {
          'status': 'success',
          'message': 'Firestore is accessible',
        };
      } catch (e) {
        if (e.toString().contains('permission-denied')) {
          results['firestore'] = {
            'status': 'warning',
            'message':
                'Firestore accessible but permission denied - check security rules',
          };
        } else {
          results['firestore'] = {
            'status': 'error',
            'message': 'Firestore error: $e',
          };
        }
      }

      // Check Authentication
      try {
        final currentUser = _auth.currentUser;
        results['auth'] = {
          'status': 'success',
          'message': 'Firebase Auth is accessible',
          'currentUser': currentUser?.uid ?? 'No user logged in',
        };
      } catch (e) {
        results['auth'] = {
          'status': 'error',
          'message': 'Firebase Auth error: $e',
        };
      }

      debugPrint('🔍 Firebase configuration check results: $results');
      return results;
    } catch (e) {
      debugPrint('❌ Error checking Firebase configuration: $e');
      return {'error': 'Failed to check configuration: $e'};
    }
  }

  /// Handle Firebase Storage bucket creation and initialization
  static Future<void> initializeStorageBucket() async {
    try {
      debugPrint('🔧 Initializing Firebase Storage bucket...');

      // First, try to check if we can access storage at all
      try {
        // Don't call listAll() on empty storage - it will fail
        // Instead, try to create a simple test file to verify access
        final testRef = _storage.ref().child('_init_test');
        await testRef.putString('init', format: PutStringFormat.raw);
        await testRef.delete(); // Clean up
        debugPrint('✅ Firebase Storage bucket is accessible and writable');
        return;
      } catch (e) {
        debugPrint('⚠️ Storage not accessible: $e');

        if (e.toString().contains('object-not-found')) {
          debugPrint('🔄 Storage bucket not found, attempting to create...');

          // Try to create a simple test file to initialize the bucket
          try {
            final testRef = _storage.ref().child('_init_test');
            await testRef.putString('init', format: PutStringFormat.raw);
            await testRef.delete(); // Clean up
            debugPrint('✅ Storage bucket initialized successfully');
          } catch (createError) {
            debugPrint('❌ Failed to create storage bucket: $createError');

            // If we still can't create, provide helpful error message
            if (createError.toString().contains('object-not-found')) {
              throw '''
Firebase Storage bucket does not exist and cannot be created automatically.

To fix this:
1. Go to Firebase Console (https://console.firebase.google.com/)
2. Select your project
3. Click "Storage" in the left sidebar
4. Click "Get started" to enable Storage
5. Choose a location for your storage bucket
6. Set up security rules (start with test mode)

After enabling Storage, restart your app and try again.
              ''';
            } else {
              rethrow;
            }
          }
        } else {
          // For other errors, provide general guidance
          throw '''
Firebase Storage is not accessible: $e

Please check:
1. Firebase Storage is enabled in your project
2. Your app has the correct Firebase configuration
3. You have proper internet connectivity
4. Firebase project is active and not suspended
              ''';
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing storage bucket: $e');
      rethrow;
    }
  }

  /// Check Firebase project status and configuration
  static Future<Map<String, dynamic>> checkProjectStatus() async {
    final results = <String, dynamic>{};

    try {
      debugPrint('🔍 Checking Firebase project status...');

      // Check if we can access Firebase at all
      try {
        final app = Firebase.app();
        results['project'] = {
          'status': 'success',
          'message': 'Firebase project accessible',
          'projectId': app.options.projectId,
          'storageBucket': app.options.storageBucket,
        };
        debugPrint('✅ Project ID: ${app.options.projectId}');
        debugPrint('✅ Storage Bucket: ${app.options.storageBucket}');
      } catch (e) {
        results['project'] = {
          'status': 'error',
          'message': 'Firebase project not accessible: $e',
        };
        debugPrint('❌ Project access error: $e');
      }

      // Check if storage bucket is configured
      try {
        final app = Firebase.app();
        final storageBucket = app.options.storageBucket;
        if (storageBucket == null || storageBucket.isEmpty) {
          results['storageConfig'] = {
            'status': 'error',
            'message': 'Storage bucket not configured in Firebase project',
          };
          debugPrint('❌ Storage bucket not configured');
        } else {
          results['storageConfig'] = {
            'status': 'success',
            'message': 'Storage bucket configured: $storageBucket',
          };
          debugPrint('✅ Storage bucket configured');
        }
      } catch (e) {
        results['storageConfig'] = {
          'status': 'error',
          'message': 'Could not check storage configuration: $e',
        };
      }

      return results;
    } catch (e) {
      debugPrint('❌ Error checking project status: $e');
      return {'error': 'Failed to check project status: $e'};
    }
  }

  /// Test Firebase Storage with a simple operation
  static Future<bool> testStorageAccess() async {
    try {
      debugPrint('🧪 Testing Firebase Storage access...');

      // Try to create a simple test file
      final testRef = _storage.ref().child('_test_access');
      await testRef.putString('test', format: PutStringFormat.raw);

      // Try to read it back
      final testData = await testRef.getData();
      if (testData != null && testData.length > 0) {
        debugPrint('✅ Storage read test passed');
      }

      // Clean up
      await testRef.delete();
      debugPrint('✅ Storage write/delete test passed');

      return true;
    } catch (e) {
      debugPrint('❌ Storage test failed: $e');
      return false;
    }
  }
}
