import 'dart:typed_data';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/job.dart';

class JobService {
  static JobService? _instance;
  static JobService get instance => _instance ??= JobService._();

  JobService._();

  final ApiService _apiService = ApiService();

  Future<Job> createJob({
    required Uint8List imageBytes,
    required String imageName,
    required String prompt,
  }) async {
    return await _apiService.createJob(
      imageBytes: imageBytes,
      imageName: imageName,
      prompt: prompt,
    );
  }

  Future<Job> createJobWithImageUrl({
    required String imageUrl,
    required String prompt,
  }) async {
    return await _apiService.createJobWithImageUrl(
      imageUrl: imageUrl,
      prompt: prompt,
    );
  }

  Future<Job> pollJobStatus({
    required int jobId,
    required Function(Job) onUpdate,
  }) async {
    return await _apiService.pollJobStatus(jobId: jobId, onUpdate: onUpdate);
  }

  Future<JobListResponse> getAllJobs({int limit = 100, int offset = 0}) async {
    return await _apiService.getAllJobs(limit: limit, offset: offset);
  }
}
