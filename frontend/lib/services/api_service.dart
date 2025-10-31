import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/job.dart';

/// API Service for communicating with the backend
class ApiService {
  // Backend API base URL - Change this to your deployed backend URL
  final String baseUrl;

  ApiService({
    this.baseUrl = 'https://flutter-ai-image-editing-web-app.vercel.app',
  });

  /// Create a new image editing job
  ///
  /// Uploads an image and prompt to the backend
  /// Returns a Job object with pending status
  Future<Job> createJob({
    required Uint8List imageBytes,
    required String imageName,
    required String prompt,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/jobs');

      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Determine content type from filename
      String mimeType = _getMimeType(imageName);

      // Add image file with proper content type
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Add prompt
      request.fields['prompt'] = prompt;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return Job.fromJson(jsonData);
      } else {
        throw ApiException(
          'Failed to create job: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw ApiException('Error creating job', e.toString());
    }
  }

  /// Create a new image editing job with an existing image URL
  ///
  /// Uploads an image URL and prompt to the backend
  /// Returns a Job object with pending status
  Future<Job> createJobWithImageUrl({
    required String imageUrl,
    required String prompt,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/jobs');
      final response = await http.post(
        uri,
        body: {'image_url': imageUrl, 'prompt': prompt},
      );
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return Job.fromJson(jsonData);
      } else {
        throw ApiException(
          'Failed to create job with image URL: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw ApiException('Error creating job with image URL', e.toString());
    }
  }

  /// Get job status by ID
  ///
  /// Use this to poll for job completion
  Future<Job> getJob(int jobId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/jobs/$jobId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return Job.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw ApiException(
          'Job not found',
          'Job with ID $jobId does not exist',
        );
      } else {
        throw ApiException(
          'Failed to get job: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw ApiException('Error getting job', e.toString());
    }
  }

  /// Get all jobs with optional filtering
  ///
  /// Used for displaying job history
  Future<JobListResponse> getAllJobs({int limit = 100, int offset = 0}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/jobs').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return JobListResponse.fromJson(jsonData);
      } else {
        throw ApiException(
          'Failed to get jobs: ${response.statusCode}',
          response.body,
        );
      }
    } catch (e) {
      throw ApiException('Error getting jobs', e.toString());
    }
  }

  /// Poll for job completion
  ///
  /// Continuously checks job status until it's completed or failed
  /// Calls onUpdate callback with the latest job status
  Future<Job> pollJobStatus({
    required int jobId,
    Duration pollInterval = const Duration(seconds: 3),
    Duration timeout = const Duration(minutes: 5),
    void Function(Job)? onUpdate,
  }) async {
    final startTime = DateTime.now();

    while (true) {
      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        throw ApiException(
          'Job polling timeout',
          'Job took too long to complete',
        );
      }

      // Get current job status
      final job = await getJob(jobId);

      // Call update callback
      onUpdate?.call(job);

      // Check if job is completed or failed
      if (job.isCompleted || job.isFailed) {
        return job;
      }

      // Wait before next poll
      await Future.delayed(pollInterval);
    }
  }

  /// Check backend health
  Future<bool> healthCheck() async {
    try {
      final uri = Uri.parse('$baseUrl/');
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Determine MIME type from filename extension
  String _getMimeType(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }
}

/// API Exception class
class ApiException implements Exception {
  final String message;
  final String details;

  ApiException(this.message, this.details);

  @override
  String toString() => '$message: $details';
}
