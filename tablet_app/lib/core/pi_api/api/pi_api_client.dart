import '../../../core/api_client.dart';

class PiApiClient {
  const PiApiClient({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<bool> isOnline() async {
    final health = await _apiClient.health();
    return health['status'] == 'ok';
  }

  Future<Map<String, dynamic>> proxyStatus() {
    return _apiClient.proxyStatus();
  }

  Future<Map<String, dynamic>> startPracticeSession() {
    return _apiClient.startSession(mode: 'practice');
  }
}
