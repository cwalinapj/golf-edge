import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  static const requestTimeout = Duration(seconds: 45);

  final String baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> health() {
    return getJson('/health');
  }

  Future<Map<String, dynamic>> currentSensors() {
    return getJson('/sensors/current');
  }

  Future<Map<String, dynamic>> proxyStatus() {
    return getJson('/proxy/status');
  }

  Future<Map<String, dynamic>> scanLaunchMonitors({
    String stationInterface = 'eth1',
  }) {
    final query = Uri(queryParameters: <String, String>{
      'station_interface': stationInterface,
    }).query;
    return getJson('/proxy/launch-monitor/scan?$query');
  }

  Future<Map<String, dynamic>> wlan0DhcpUp({String interface = 'wlan0'}) {
    return postJson(
      '/admin/wlan0/dhcp-up',
      body: <String, dynamic>{'interface': interface},
    );
  }

  Future<Map<String, dynamic>> scanWlan0Wifi({String interface = 'wlan0'}) {
    return getJson('/admin/wlan0/wifi/scan?interface=$interface');
  }

  Future<Map<String, dynamic>> authenticateWlan0Wifi({
    required String ssid,
    required String password,
    String? bssid,
    String interface = 'wlan0',
    bool save = true,
  }) {
    return postJson(
      '/admin/wlan0/wifi/authenticate',
      body: <String, dynamic>{
        'ssid': ssid,
        'password': password,
        if (bssid != null && bssid.isNotEmpty) 'bssid': bssid,
        'interface': interface,
        'save': save,
      },
    );
  }

  Future<Map<String, dynamic>> bindLaunchMonitor({
    required String ssid,
    required String bssid,
    required String passphrase,
    required String capabilities,
    required String ownerKey,
    String stationInterface = 'eth1',
    bool keepConnected = true,
  }) {
    return postJson(
      '/proxy/launch-monitor/bind',
      body: <String, dynamic>{
        'ssid': ssid,
        'bssid': bssid,
        'passphrase': passphrase,
        'capabilities': capabilities,
        'owner_key': ownerKey,
        'station_interface': stationInterface,
        'keep_connected': keepConnected,
      },
    );
  }

  Future<Map<String, dynamic>> startSession({
    required String mode,
    String? locationLabel,
  }) {
    return postJson(
      '/sessions/start',
      body: <String, dynamic>{
        'mode': mode,
        if (locationLabel != null && locationLabel.trim().isNotEmpty)
          'location_label': locationLabel.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> stopSession(String sessionId) {
    return postJson('/sessions/$sessionId/stop');
  }

  Future<Map<String, dynamic>> createSwingEvent(
    String sessionId, {
    String? club,
    String? shotType,
    double? targetDistance,
    String? intentTag,
    int? holeNumber,
    String? lie,
  }) {
    return postJson(
      '/events/$sessionId',
      body: <String, dynamic>{
        if (club != null && club.trim().isNotEmpty) 'club': club.trim(),
        if (shotType != null && shotType.trim().isNotEmpty)
          'shot_type': shotType.trim(),
        if (targetDistance != null) 'target_distance': targetDistance,
        if (intentTag != null && intentTag.trim().isNotEmpty)
          'intent_tag': intentTag.trim(),
        if (holeNumber != null) 'hole_number': holeNumber,
        if (lie != null && lie.trim().isNotEmpty) 'lie': lie.trim(),
      },
    );
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    final response =
        await _client.get(Uri.parse('$baseUrl$path')).timeout(requestTimeout);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body ?? <String, dynamic>{}),
        )
        .timeout(requestTimeout);
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiClientException(
        'Request failed with status ${response.statusCode}: ${_summarizeBody(response.body)}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiClientException(
      'Expected a JSON object response but received: ${_summarizeBody(response.body)}',
    );
  }

  String _summarizeBody(String body) {
    const maxLength = 200;
    if (body.length <= maxLength) {
      return body;
    }
    return '${body.substring(0, maxLength)}...';
  }
}

class ApiClientException implements Exception {
  const ApiClientException(this.message);

  final String message;

  @override
  String toString() => 'ApiClientException: $message';
}
