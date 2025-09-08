import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/firebase_auth_service.dart';
import '../services/document_service.dart';
import 'thank_you_screen.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  List<DocumentSlot> documentSlots = [
    DocumentSlot(title: 'Contract or Agreement'),
    DocumentSlot(title: 'Identification Document'),
    DocumentSlot(title: 'Supporting Evidence'),
  ];

  bool isUploading = false;
  List<Map<String, dynamic>> uploadedDocuments = [];

  Future<void> _pickFile(int index) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          documentSlots[index].filePath = result.files.single.path!;
          documentSlots[index].fileName = result.files.single.name;
          documentSlots[index].fileSize = result.files.single.size;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      documentSlots[index].filePath = null;
      documentSlots[index].fileName = null;
      documentSlots[index].fileSize = null;
    });
  }

  void _addNewSlot() {
    setState(() {
      documentSlots.add(DocumentSlot(title: 'Additional Document'));
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _submitDocuments() async {
    final hasDocuments = documentSlots.any((slot) => slot.filePath != null);

    if (!hasDocuments) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one document'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final firebaseAuthService = Provider.of<FirebaseAuthService>(
        context,
        listen: false,
      );
      final currentUser = firebaseAuthService.currentUser;

      if (currentUser == null) {
        throw 'User not authenticated';
      }

      // Check Firebase configuration before proceeding
      debugPrint('🔍 Checking Firebase configuration...');
      final configCheck = await DocumentService.checkFirebaseConfiguration();

      // Check project status first
      if (configCheck['project']?['status'] == 'error') {
        throw 'Firebase project issue: ${configCheck['project']['message']}';
      }

      if (configCheck['storageConfig']?['status'] == 'error') {
        throw '''
Storage bucket not configured: ${configCheck['storageConfig']['message']}

To fix this:
1. Go to Firebase Console (https://console.firebase.google.com/)
2. Select your project: ${configCheck['project']?['projectId'] ?? 'Unknown'}
3. Click "Storage" in the left sidebar
4. Click "Get started" to enable Storage
5. Choose a location for your storage bucket
6. Set up security rules (start with test mode)

After enabling Storage, restart your app and try again.
        ''';
      }

      if (configCheck['storage']?['status'] == 'error') {
        throw 'Firebase Storage is not accessible: ${configCheck['storage']['message']}';
      }

      if (configCheck['firestore']?['status'] == 'error') {
        throw 'Firestore is not accessible: ${configCheck['firestore']['message']}';
      }

      // Show warnings but don't block uploads
      if (configCheck['firestore']?['status'] == 'warning') {
        debugPrint(
          '⚠️ Firestore warning: ${configCheck['firestore']['message']}',
        );
        // Don't throw - just log the warning
      }

      debugPrint('✅ Firebase configuration check passed');
      debugPrint('📊 Project ID: ${configCheck['project']?['projectId']}');
      debugPrint(
        '📊 Storage Bucket: ${configCheck['project']?['storageBucket']}',
      );

      uploadedDocuments.clear();

      // Upload each document
      for (int i = 0; i < documentSlots.length; i++) {
        final slot = documentSlots[i];
        if (slot.filePath != null) {
          try {
            debugPrint(
              '📤 Uploading document ${i + 1}/${documentSlots.length}: ${slot.fileName}',
            );

            final result = await DocumentService.uploadDocument(
              filePath: slot.filePath!,
              fileName: slot.fileName!,
              documentType: slot.title,
              description: slot.descriptionController.text.trim(),
              userId: currentUser.uid,
              additionalData: {'slotIndex': i, 'originalTitle': slot.title},
            );

            uploadedDocuments.add(result);
            debugPrint(
              '✅ Document uploaded successfully: ${result['fileName']}',
            );
          } catch (e) {
            debugPrint('❌ Error uploading document ${slot.fileName}: $e');
            _showErrorSnackBar('Failed to upload ${slot.fileName}: $e');
            setState(() {
              isUploading = false;
            });
            return;
          }
        }
      }

      debugPrint(
        '🎉 All documents uploaded successfully! Total: ${uploadedDocuments.length}',
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${uploadedDocuments.length} documents uploaded successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate to thank you screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ThankYouScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Error during document submission: $e');
      if (mounted) {
        _showErrorSnackBar('Upload failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Help',
          textColor: Colors.white,
          onPressed: () => _showFirebaseHelpDialog(),
        ),
      ),
    );
  }

  void _showFirebaseHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              'Firebase Storage Issue',
              style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The document upload failed due to a Firebase Storage configuration issue.',
              style: GoogleFonts.roboto(),
            ),
            const SizedBox(height: 16),
            Text(
              'Common causes and solutions:',
              style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('• Firebase Storage is not enabled in your project'),
            Text('• Storage rules are too restrictive'),
            Text('• Project configuration is missing'),
            const SizedBox(height: 16),
            Text(
              'Please check your Firebase Console and ensure:',
              style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text('1. Storage is enabled in your project'),
            Text('2. Storage rules allow authenticated uploads'),
            Text('3. Your app configuration is correct'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.roboto(color: const Color(0xFF2196F3)),
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
          'Upload Documents',
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
        child: Column(
          children: [
            // Header info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Secure Document Upload',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload your legal documents securely. Supported formats: PDF, DOC, DOCX, JPG, PNG',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Document slots
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: documentSlots.length + 1, // +1 for add button
                itemBuilder: (context, index) {
                  if (index == documentSlots.length) {
                    return _buildAddDocumentButton();
                  }
                  return _buildDocumentSlot(index);
                },
              ),
            ),

            // Submit button
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isUploading ? null : _submitDocuments,
                  child: isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Uploading...',
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Send to Lawyer',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSlot(int index) {
    final slot = documentSlots[index];
    final hasFile = slot.filePath != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFile ? Colors.green[300]! : Colors.grey[300]!,
          width: hasFile ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasFile ? Icons.check_circle : Icons.upload_file,
                color: hasFile ? Colors.green[600] : Colors.grey[500],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  slot.title,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (hasFile)
                IconButton(
                  onPressed: () => _removeFile(index),
                  icon: Icon(Icons.close, color: Colors.red[600]),
                ),
            ],
          ),

          const SizedBox(height: 12),

          if (hasFile) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.fileName!,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                        Text(
                          _formatFileSize(slot.fileSize!),
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: () => _pickFile(index),
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 32, color: Colors.grey[500]),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to upload file',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Description field
          TextField(
            controller: slot.descriptionController,
            decoration: InputDecoration(
              hintText: 'Add description or notes (optional)',
              hintStyle: GoogleFonts.roboto(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2196F3)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildAddDocumentButton() {
    return GestureDetector(
      onTap: _addNewSlot,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.blue[300]!,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.blue[600], size: 24),
            const SizedBox(width: 12),
            Text(
              'Add Another Document',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentSlot {
  final String title;
  String? filePath;
  String? fileName;
  int? fileSize;
  final TextEditingController descriptionController = TextEditingController();

  DocumentSlot({required this.title});

  void dispose() {
    descriptionController.dispose();
  }
}
