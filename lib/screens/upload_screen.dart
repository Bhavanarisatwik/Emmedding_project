import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _tagController = TextEditingController();
  final _apiService = ApiService();

  File? _selectedFile;
  String? _selectedFileName;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _error;
  String? _successMessage;

  final List<Map<String, dynamic>> _fileTypes = [
    {'type': 'image', 'icon': Icons.image_outlined, 'label': 'Image', 'color': Colors.orange},
    {'type': 'video', 'icon': Icons.videocam_outlined, 'label': 'Video', 'color': Color(0xFFA855F7)},
    {'type': 'document', 'icon': Icons.description_outlined, 'label': 'Document', 'color': AppTheme.accentBlue},
  ];

  @override
  void dispose() {
    _tagController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type) async {
    try {
      // Clear previous messages when picking a new file
      setState(() {
        _error = null;
        _successMessage = null;
      });

      FilePickerResult? result;

      if (type == 'image') {
        final picker = ImagePicker();
        final image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() {
            _selectedFile = File(image.path);
            _selectedFileName = image.name;
          });
        }
        return;
      } else if (type == 'video') {
        final picker = ImagePicker();
        final video = await picker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          setState(() {
            _selectedFile = File(video.path);
            _selectedFileName = video.name;
          });
        }
        return;
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'docx', 'txt', 'md', 'csv'],
        );
      }

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result!.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick file: $e');
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _error = null;
      _successMessage = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final result = await _apiService.uploadFile(
        file: _selectedFile!,
        tag: _tagController.text.trim(),
        onProgress: (progress) {
          setState(() => _uploadProgress = progress / 100);
        },
      );

      HapticFeedback.heavyImpact();
      setState(() {
        _isUploading = false;
        _successMessage = '${result.filename} uploaded successfully!';
        _selectedFile = null;
        _selectedFileName = null;
        _tagController.clear();
      });

      // Clear success message after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _successMessage = null);
      });
    } on ApiException catch (e) {
      setState(() {
        _isUploading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _error = 'Upload failed: $e';
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Files'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Add to Knowledge Base',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload images, videos, or documents to make them searchable',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),

            // File type selection (always visible)
            Row(
              children: _fileTypes.map((type) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _FileTypeCard(
                      icon: type['icon'],
                      label: type['label'],
                      color: type['color'],
                      onTap: () => _pickFile(type['type']),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Selected file info + tag input (only when file selected)
            if (_selectedFile != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.insert_drive_file,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFileName ?? 'Unknown file',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFileSize(_selectedFile!.lengthSync()),
                            style: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _clearSelection,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tag input
              TextField(
                controller: _tagController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Add a tag (optional)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  hintText: 'e.g., "Devi photos", "Work notes"',
                  prefixIcon: Icon(Icons.tag, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Error message — ALWAYS visible, outside file conditional
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 13, height: 1.4),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _error = null),
                      child: Icon(Icons.close, size: 16, color: AppTheme.error.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Success message — ALWAYS visible, outside file conditional
            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: AppTheme.success, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Upload progress (when uploading)
            if (_isUploading) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Uploading...',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: AppTheme.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Upload button (only when file selected)
            if (_selectedFile != null) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: _isUploading
                        ? null
                        : const LinearGradient(
                            colors: [AppTheme.accentBlue, AppTheme.accentBlueDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isUploading
                        ? null
                        : [
                            BoxShadow(
                              color: AppTheme.accentGlow.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: AppTheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isUploading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Uploading ${(_uploadProgress * 100).toInt()}%',
                                style: const TextStyle(color: AppTheme.textSecondary),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, color: AppTheme.primaryDark),
                              SizedBox(width: 8),
                              Text(
                                'Upload & Index',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ] else if (_successMessage == null) ...[
              // Empty state (only when no file selected and no success message)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: AppTheme.accentBlue.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a file type above to get started',
                      style: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _FileTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FileTypeCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
