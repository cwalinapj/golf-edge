import 'package:flutter/services.dart';

class ControllerWifiChannel {
  const ControllerWifiChannel();

  static const _channel = MethodChannel('rail_golf/controller_wifi');

  Future<void> saveControllerNetwork({
    required String ssid,
    required String password,
  }) {
    return _channel.invokeMethod<void>(
      'saveControllerNetwork',
      <String, Object?>{
        'ssid': ssid,
        'password': password,
      },
    );
  }
}
