/// Job model matching the backend API response
class Job {
  final int id;
  final String prompt;
  final String status;
  final String? originalImageUrl;
  final String? editedImageUrl;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Job({
    required this.id,
    required this.prompt,
    required this.status,
    this.originalImageUrl,
    this.editedImageUrl,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Job from JSON
  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as int,
      prompt: json['prompt'] as String,
      status: json['status'] as String,
      originalImageUrl: json['original_image_url'] as String?,
      editedImageUrl: json['edited_image_url'] as String?,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Job to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'status': status,
      'original_image_url': originalImageUrl,
      'edited_image_url': editedImageUrl,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if job is completed
  bool get isCompleted => status == 'completed';

  /// Check if job is processing
  bool get isProcessing => status == 'processing';

  /// Check if job is pending
  bool get isPending => status == 'pending';

  /// Check if job failed
  bool get isFailed => status == 'failed';

  @override
  String toString() {
    return 'Job(id: $id, status: $status, prompt: $prompt)';
  }
}

/// Job list response
class JobListResponse {
  final List<Job> jobs;
  final int total;

  JobListResponse({
    required this.jobs,
    required this.total,
  });

  factory JobListResponse.fromJson(Map<String, dynamic> json) {
    return JobListResponse(
      jobs: (json['jobs'] as List)
          .map((jobJson) => Job.fromJson(jobJson as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }
}
