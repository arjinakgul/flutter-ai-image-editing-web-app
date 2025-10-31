/// Application configuration
class Config {
  // Backend API URL
  // Change this to your deployed backend URL for production
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // Polling configuration
  static const Duration pollInterval = Duration(seconds: 3);
  static const Duration pollTimeout = Duration(minutes: 5);

  // UI configuration
  static const int maxImageSizeMB = 10;
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
}
