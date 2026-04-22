import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rail_golf_tablet/app.dart';
import 'package:rail_golf_tablet/core/api_client.dart';
import 'package:rail_golf_tablet/core/wallet_user.dart';
import 'package:rail_golf_tablet/core/wifi_scan_channel.dart';
import 'package:rail_golf_tablet/wifi_setup_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'wallet_user.address': '11111111111111111111111111111111',
      'wallet_user.chain_id': 'eip155:1',
      'wallet_user.namespace': 'eip155',
      'wallet_user.connected_at': 1,
    });
  });

  testWidgets('always renders the wallet gate on app launch', (tester) async {
    await tester.pumpWidget(const RailGolfApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Find Launch Monitor'), findsNothing);
  });

  testWidgets('renders the wallet gate when no user is connected',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const RailGolfApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(
      find.text('Please login with your web 3.0 wallet or as a guest.'),
      findsOneWidget,
    );
    expect(find.text('Login as guest'), findsOneWidget);
  });

  testWidgets('guest login does not persist as a remembered user',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const RailGolfApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login as guest'));
    await tester.pumpAndSettle();

    expect(find.text('Guest'), findsOneWidget);
    expect(find.text('Connect to Rail Golf Controller'), findsOneWidget);
    expect(find.text('Find Launch Monitor'), findsNothing);
  });

  testWidgets('selecting a launch monitor replaces scan with connect',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WalletUserScope(
          user: WalletUser.guest(),
          child: Scaffold(
            body: WifiSetupScreen(channel: _FakeWifiScanChannel()),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FS M2-041799'));
    await tester.pumpAndSettle();

    expect(find.text('Find Launch Monitor'), findsNothing);
    expect(find.text('Connect'), findsNWidgets(2));
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('FS M2-041799'), findsOneWidget);
  });

  testWidgets('successful launch monitor save unlocks saved state',
      (tester) async {
    final apiClient = _FakeApiClient();

    await tester.pumpWidget(
      MaterialApp(
        home: WalletUserScope(
          user: WalletUser.guest(),
          child: Scaffold(
            body: WifiSetupScreen(
              channel: _FakeWifiScanChannel(),
              apiClient: apiClient,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FS M2-041799'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'mevo-passcode');
    await tester.tap(find.widgetWithText(FilledButton, 'Connect'));
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsNWidgets(2));
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(apiClient.boundSsid, 'FS M2-041799');
    expect(apiClient.boundBssid, 'AA:BB:CC:DD:EE:FF');
  });
}

class _FakeWifiScanChannel extends WifiScanChannel {
  WifiBinding? savedBinding;

  @override
  Future<List<WifiNetwork>> scan() async {
    return const [
      WifiNetwork(
        ssid: 'FS M2-041799',
        bssid: 'AA:BB:CC:DD:EE:FF',
        level: -40,
        frequency: 2412,
        capabilities: '[WPA2-PSK-CCMP][ESS]',
      ),
    ];
  }

  @override
  Future<void> saveBinding(WifiBinding binding) async {
    savedBinding = binding;
  }
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://pi.local');

  String? boundSsid;
  String? boundBssid;

  @override
  Future<Map<String, dynamic>> bindLaunchMonitor({
    required String ssid,
    required String bssid,
    required String passphrase,
    required String capabilities,
    required String ownerKey,
    String? stationMac,
    String stationInterface = 'eth1',
    bool keepConnected = true,
  }) async {
    boundSsid = ssid;
    boundBssid = bssid;
    return {
      'status': 'connected',
      'ssid': ssid,
      'bssid': bssid,
      'station_interface': stationInterface,
      'keep_connected': keepConnected,
      'connected': true,
      'detail': 'connected',
    };
  }
}
