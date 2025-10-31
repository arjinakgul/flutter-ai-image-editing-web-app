import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import '../services/job_service.dart';
import '../models/job.dart';
import '../widgets/before_after.dart';
import 'history_page.dart';

class HomePage extends StatefulWidget {
  final Job? currentJob;
  const HomePage({super.key, this.currentJob});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State variables
  Uint8List? _imageBytes;
  String? _imageName;
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';
  Job? _currentJob;
  String? _originalImageUrl;
  String? _editedImageUrl;
  int _selectedImageIndex = -1;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentJob = widget.currentJob;
    if (_currentJob != null) {
      _originalImageUrl = _currentJob!.originalImageUrl;
      _editedImageUrl = _currentJob!.editedImageUrl;
    }
  }

  // Pick image from file system
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _imageBytes = result.files.first.bytes;
          _imageName = result.files.first.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  // Clear selected image and reset
  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _imageName = null;
      _editedImageUrl = null;
      _originalImageUrl = null;
      _currentJob = null;
      _statusMessage = '';
      _promptController.clear();
      _selectedImageIndex = -1;
    });
  }

  // Download the edited image
  Future<void> _downloadEditedImage() async {
    if (_selectedImageIndex == -1) return;

    try {
      // Fetch the image
      final response = await http.get(
        Uri.parse(
          _selectedImageIndex == 0
              ? _currentJob!.originalImageUrl!
              : _currentJob!.editedImageUrl!,
        ),
      );
      if (response.statusCode == 200) {
        // Create a blob and trigger download
        final blob = html.Blob([response.bodyBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute(
            'download',
            'edited_image_${DateTime.now().millisecondsSinceEpoch}.png',
          )
          ..click();
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Generate edited image
  Future<void> _generateImage() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a prompt'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_imageBytes == null && _currentJob == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Uploading image...';
      _originalImageUrl = null;
      _editedImageUrl = null;
    });

    try {
      Job? job;
      if (_selectedImageIndex != -1) {
        job = await JobService.instance.createJobWithImageUrl(
          imageUrl: _selectedImageIndex == 0
              ? _currentJob!.originalImageUrl!
              : _currentJob!.editedImageUrl!,
          prompt: _promptController.text,
        );
      } else {
        job = await JobService.instance.createJob(
          imageBytes: _imageBytes!,
          imageName: _imageName ?? 'image.png',
          prompt: _promptController.text,
        );
      }

      setState(() {
        _currentJob = job;
        _statusMessage = 'Processing image...';
        _originalImageUrl = job?.originalImageUrl;
      });

      // Poll for completion
      final completedJob = await JobService.instance.pollJobStatus(
        jobId: job.id,
        onUpdate: (updatedJob) {
          if (mounted) {
            setState(() {
              _currentJob = updatedJob;
              if (updatedJob.isProcessing) {
                _statusMessage = 'AI is editing your image...';
              }
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _currentJob = completedJob;
          _isLoading = false;

          if (completedJob.isCompleted && completedJob.editedImageUrl != null) {
            _editedImageUrl = completedJob.editedImageUrl;
            _statusMessage =
                'Image ready! Choose a version to continue or upload a new image.';
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image edited successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (completedJob.isFailed) {
            _statusMessage =
                'Failed: ${completedJob.errorMessage ?? "Unknown error"}';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: ${completedJob.errorMessage ?? "Unknown error"}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Unexpected error occurred';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build the image display area - shows upload, loading, or results
  Widget _buildImageDisplayArea() {
    // Show BeforeAfter comparison - either loading or completed
    if (_currentJob != null && _originalImageUrl != null) {
      return BeforeAfter(
        beforeImageUrl: _originalImageUrl!,
        afterImageUrl: _editedImageUrl, // null while loading, shows skeleton
        showLabels: false,
        height: 300,
        selectedIndex: _selectedImageIndex,
        onSelected: (index) => setState(() => _selectedImageIndex = index),
      );
    }

    // Show upload area (default)
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _imageBytes == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Click to upload an image',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supports: JPG, PNG, WEBP',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  // Display selected image
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                    ),
                  ),
                  // Clear button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: _clearImage,
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  // Image name badge
                  if (_imageName != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _imageName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Image Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
            tooltip: 'View History',
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const SizedBox(height: 24),
              Text(
                'Upload an image and describe how you want to edit it',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Main content area
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Image display area - shows upload or results
                        Expanded(child: _buildImageDisplayArea()),

                        const SizedBox(height: 24),

                        // Prompt input area
                        TextField(
                          controller: _promptController,
                          decoration: const InputDecoration(
                            labelText: 'Explain the new version of the image',
                            hintText: 'e.g., Add a sunset in the background',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.edit),
                          ),
                          maxLines: 3,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),

                        // Status message
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _statusMessage.isNotEmpty ? _statusMessage : '',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ),

                        // Action buttons
                        Row(
                          children: [
                            // New Image button (shown after completion)
                            if (_currentJob != null &&
                                !_isLoading &&
                                _currentJob!.isCompleted)
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    onPressed: _clearImage,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text(
                                      'New Image',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ),
                            if (_currentJob != null &&
                                !_isLoading &&
                                _currentJob!.isCompleted)
                              const SizedBox(width: 16),
                            // Generate button
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      (_imageBytes != null && !_isLoading ||
                                          (_currentJob != null &&
                                              _selectedImageIndex != -1))
                                      ? _generateImage
                                      : null,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.auto_awesome),
                                  label: Text(
                                    _isLoading ? '' : 'Generate',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            // Download button (shown when edited image exists)
                            if (_selectedImageIndex != -1 && !_isLoading)
                              const SizedBox(width: 16),
                            if (_selectedImageIndex != -1 && !_isLoading)
                              SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _downloadEditedImage,
                                  icon: const Icon(Icons.download),
                                  label: const Text(
                                    'Download',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
