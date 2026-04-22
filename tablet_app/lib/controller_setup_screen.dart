import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/api_client.dart';
import 'core/controller_wifi_channel.dart';
import 'core/wifi_scan_channel.dart';

class ControllerSetupScreen extends StatefulWidget {
  const ControllerSetupScreen({
    required this.onConnected,
    this.channel = const ControllerWifiChannel(),
    this.scanChannel = const WifiScanChannel(),
    this.apiClient,
    super.key,
  });

  final VoidCallback onConnected;
  final ControllerWifiChannel channel;
  final WifiScanChannel scanChannel;
  final ApiClient? apiClient;

  @override
  State<ControllerSetupScreen> createState() => _ControllerSetupScreenState();
}

class _ControllerSetupScreenState extends State<ControllerSetupScreen> {
  final _ssidController = TextEditingController(text: 'railgolf');
  final _passwordController = TextEditingController(text: 'password');
  bool _busy = false;
  bool _scanning = false;
  bool _piBusy = false;
  bool _showPassword = false;
  String? _status;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _scanForController() async {
    setState(() {
      _scanning = true;
      _status = 'Scanning for Rail Golf Controller...';
    });

    try {
      final networks = await widget.scanChannel.scan();
      final matches = networks
          .where((network) => network.ssid.toLowerCase() == 'railgolf')
          .toList()
        ..sort((a, b) => b.level.compareTo(a.level));
      if (!mounted) {
        return;
      }
      if (matches.isEmpty) {
        setState(
          () => _status =
              'Controller not found. Make sure wlan1 is broadcasting railgolf, then scan again.',
        );
        return;
      }

      final best = matches.first;
      setState(() {
        _ssidController.text = best.ssid;
        _status = 'Found ${best.ssid} on ${best.band}.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _status = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  Future<void> _connect() async {
    final ssid = _ssidController.text.trim();
    final password = _passwordController.text;
    if (ssid.isEmpty) {
      setState(() => _status = 'Enter the controller network name.');
      return;
    }
    if (password.length < 8) {
      setState(() => _status = 'Password must be at least 8 characters.');
      return;
    }

    setState(() {
      _busy = true;
      _status = 'Connecting to Rail Golf Controller...';
    });

    try {
      await widget.channel.saveControllerNetwork(
        ssid: ssid,
        password: password,
      );
      if (!mounted) {
        return;
      }
      setState(() => _status = 'Controller connected and saved.');
      widget.onConnected();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _status = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _testPiConnection() async {
    await _runPiAction(
      label: 'Testing Pi API...',
      action: () async {
        final health = await _apiClient.health();
        return 'Pi API ${health['status'] ?? 'online'}';
      },
    );
  }

  Future<void> _getProxyStatus() async {
    await _runPiAction(
      label: 'Reading proxy status...',
      action: () async {
        final status = await _apiClient.proxyStatus();
        final openPorts =
            (status['open_ports'] as List<dynamic>? ?? const []).join(', ');
        return 'Proxy ${status['status']}; Mevo ${status['mevo_connected'] == true ? 'available' : 'not ready'}; ports ${openPorts.isEmpty ? 'none' : openPorts}';
      },
    );
  }

  Future<void> _showMevoInfo() async {
    await _runPiAction(
      label: 'Reading Mevo info...',
      action: () async {
        final info = await _apiClient.mevoInfo();
        return info['detail'] as String? ?? 'No Mevo discovery response yet.';
      },
    );
  }

  Future<void> _runPiAction({
    required String label,
    required Future<String> Function() action,
  }) async {
    setState(() {
      _piBusy = true;
      _status = label;
    });

    try {
      final message = await action();
      if (mounted) {
        setState(() => _status = message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _status = _friendlyError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _piBusy = false);
      }
    }
  }

  ApiClient get _apiClient {
    return widget.apiClient ??
        ApiClient(
          baseUrl: const String.fromEnvironment(
            'RAIL_GOLF_API_BASE_URL',
            defaultValue: 'http://192.168.4.1:8000',
          ),
        );
  }

  String _friendlyError(Object error) {
    if (error is PlatformException) {
      return error.message ?? error.code;
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final canConnect = _ssidController.text.trim().isNotEmpty &&
        _passwordController.text.length >= 8;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xff18211c),
                border: Border.all(color: const Color(0xff2b3a30)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Connect to Rail Golf Controller',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _busy || _scanning ? null : _scanForController,
                    icon: _scanning
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.radar_outlined),
                    label: const Text('Scan for Controller'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _ssidController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Controller network',
                      prefixIcon: Icon(Icons.router_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        tooltip:
                            _showPassword ? 'Hide password' : 'Show password',
                        onPressed: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (_status != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _status!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed:
                        _busy || _scanning || !canConnect ? null : _connect,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi),
                    label: const Text('Connect'),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _piBusy ? null : _testPiConnection,
                        icon: const Icon(Icons.api_outlined),
                        label: const Text('Test Pi Connection'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _piBusy ? null : _getProxyStatus,
                        icon: const Icon(Icons.route_outlined),
                        label: const Text('Get Proxy Status'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _piBusy ? null : _showMevoInfo,
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Show Mevo Info'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
