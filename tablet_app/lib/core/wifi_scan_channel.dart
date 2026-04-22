import 'package:flutter/services.dart';

class WifiScanChannel {
  const WifiScanChannel();

  static const _channel = MethodChannel('golf_edge/wifi_scan');

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

  factory WifiNetwork.fromPlatform(Map<Object?, Object?> json) {
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
  });

  final String ssid;
  final String bssid;
  final String capabilities;
  final String passphrase;

  Map<String, Object?> toJson() {
    return {
      'ssid': ssid,
      'bssid': bssid,
      'capabilities': capabilities,
      'passphrase': passphrase,
    };
  }
}
