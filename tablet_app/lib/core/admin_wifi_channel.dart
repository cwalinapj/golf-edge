import 'package:flutter/services.dart';

class AdminWifiChannel {
  const AdminWifiChannel();

  static const _channel = MethodChannel('rail_golf/admin_wifi');

  Future<void> connectSetupAp({
    String ssid = 'railgolf',
    String password = 'password',
  }) {
    return _channel.invokeMethod<void>(
      'connectSetupAp',
      <String, Object?>{
        'ssid': ssid,
        'password': password,
      },
    );
  }
}
