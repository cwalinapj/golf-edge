import 'package:flutter/services.dart';

import 'api_client.dart';

class WifiScanChannel {
  const WifiScanChannel();

  static const _channel = MethodChannel('rail_golf/wifi_scan');

  Future<List<WifiNetwork>> scan() async {
    final results = await _channel.invokeListMethod<Object?>('scanWifi');
    return (results ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(WifiNetwork.fromPlatform)
        .toList();
  }

  Future<void> saveBinding(WifiBinding binding) {
    return _channel.invokeMethod<void>('saveWifiBinding', binding.toJson());
  }
}

class PiWifiScanChannel extends WifiScanChannel {
  const PiWifiScanChannel(this.apiClient);

  final ApiClient apiClient;

  @override
  Future<List<WifiNetwork>> scan() async {
    final response = await apiClient.scanLaunchMonitors();
    final networks = response['networks'];
    if (networks is! List) {
      return const [];
    }
    return networks
        .whereType<Map<String, dynamic>>()
        .map(WifiNetwork.fromJson)
        .toList();
  }
}

class WifiNetwork {
  const WifiNetwork({
    required this.ssid,
    required this.bssid,
    required this.level,
    required this.frequency,
    required this.capabilities,
  });

  final String ssid;
  final String bssid;
  final int level;
  final int frequency;
  final String capabilities;

  bool get secured =>
      capabilities.contains('WEP') ||
      capabilities.contains('WPA') ||
      capabilities.contains('SAE');

  String get band => frequency >= 4900 ? '5 GHz' : '2.4 GHz';
  bool get isEthernetTarget => capabilities == 'ETHERNET';
  String get transportLabel => isEthernetTarget ? 'Controller bridge' : band;

  factory WifiNetwork.fromPlatform(Map<Object?, Object?> json) {
    return WifiNetwork(
      ssid: json['ssid'] as String? ?? '',
      bssid: json['bssid'] as String? ?? '',
      level: json['level'] as int? ?? -100,
      frequency: json['frequency'] as int? ?? 0,
      capabilities: json['capabilities'] as String? ?? '',
    );
  }

  factory WifiNetwork.fromJson(Map<String, dynamic> json) {
    return WifiNetwork(
      ssid: json['ssid'] as String? ?? '',
      bssid: json['bssid'] as String? ?? '',
      level: json['level'] as int? ?? -100,
      frequency: json['frequency'] as int? ?? 0,
      capabilities: json['capabilities'] as String? ?? '',
    );
  }
}

class WifiBinding {
  const WifiBinding({
    required this.ssid,
    required this.bssid,
    required this.capabilities,
    required this.passphrase,
    required this.ownerKey,
    required this.persist,
  });

  final String ssid;
  final String bssid;
  final String capabilities;
  final String passphrase;
  final String ownerKey;
  final bool persist;

  Map<String, Object?> toJson() {
    return {
      'ssid': ssid,
      'bssid': bssid,
      'capabilities': capabilities,
      'passphrase': passphrase,
      'ownerKey': ownerKey,
      'persist': persist,
    };
  }
}
