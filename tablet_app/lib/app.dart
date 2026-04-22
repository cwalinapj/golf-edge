import 'package:flutter/material.dart';

import 'controller_setup_screen.dart';
import 'core/api_client.dart';
import 'core/models.dart';
import 'core/wallet_user.dart';
import 'wallet_connect_gate.dart';
import 'wifi_setup_screen.dart';

class RailGolfApp extends StatefulWidget {
  const RailGolfApp({super.key});

  static const apiBaseUrl = String.fromEnvironment(
    'RAIL_GOLF_API_BASE_URL',
    defaultValue: 'http://192.168.4.1:8000',
  );

  @override
  State<RailGolfApp> createState() => _RailGolfAppState();
}

class _RailGolfAppState extends State<RailGolfApp> {
  final _walletStore = WalletUserStore();
  WalletUser? _walletUser;

  @override
  void initState() {
    super.initState();
    _walletStore.clear();
  }

  Future<void> _setWalletUser(WalletUser user) async {
    await _walletStore.save(user);
    if (mounted) {
      setState(() => _walletUser = user);
    }
  }

  Future<void> _clearWalletUser() async {
    await _walletStore.clear();
    if (mounted) {
      setState(() => _walletUser = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletUser = _walletUser;
    return MaterialApp(
      title: 'Rail Golf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2e7d32),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff101613),
      ),
      home: walletUser == null
          ? WalletConnectGate(
              onConnected: _setWalletUser,
              onGuest: () => setState(() => _walletUser = WalletUser.guest()),
            )
          : WalletUserScope(
              user: walletUser,
              child: WifiSetupHost(
                walletUser: walletUser,
                onSignOut: _clearWalletUser,
              ),
            ),
    );
  }
}

class WifiSetupHost extends StatelessWidget {
  const WifiSetupHost({
    required this.walletUser,
    required this.onSignOut,
    super.key,
  });

  final WalletUser walletUser;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _WifiSetupFlow(
          walletUser: walletUser,
          onSignOut: onSignOut,
        ),
      ),
    );
  }
}

class _WifiSetupFlow extends StatefulWidget {
  const _WifiSetupFlow({
    required this.walletUser,
    required this.onSignOut,
  });

  final WalletUser walletUser;
  final VoidCallback onSignOut;

  @override
  State<_WifiSetupFlow> createState() => _WifiSetupFlowState();
}

class _WifiSetupFlowState extends State<_WifiSetupFlow> {
  bool _controllerConnected = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(
            children: [
              const Icon(Icons.sports_golf, size: 34),
              const SizedBox(width: 12),
              const Text(
                'Rail Golf',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              _WalletChip(user: widget.walletUser, onSignOut: widget.onSignOut),
            ],
          ),
        ),
        Expanded(
          child: _controllerConnected
              ? const WifiSetupScreen()
              : ControllerSetupScreen(
                  onConnected: () {
                    setState(() => _controllerConnected = true);
                  },
                ),
        ),
      ],
    );
  }
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({
    required this.user,
    required this.onSignOut,
  });

  final WalletUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Wallet',
      onSelected: (value) {
        if (value == 'sign_out') {
          onSignOut();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'sign_out', child: Text('Disconnect')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 18),
            const SizedBox(width: 8),
            Text(user.shortAddress),
          ],
        ),
      ),
    );
  }
}

class RailGolfDashboard extends StatefulWidget {
  const RailGolfDashboard({required this.apiClient, super.key});

  final ApiClient apiClient;

  @override
  State<RailGolfDashboard> createState() => _RailGolfDashboardState();
}

class _RailGolfDashboardState extends State<RailGolfDashboard> {
  final _locationController = TextEditingController(text: 'Garage Bay');
  final _targetController = TextEditingController(text: '150');
  final _holeController = TextEditingController(text: '1');

  ApiConnectionState _connection = const ApiConnectionState(
    online: false,
    label: 'Checking Pi',
  );
  GolfSession? _activeSession;
  SensorSnapshot? _sensors;
  ProxyStatus? _proxyStatus;
  String _mode = 'practice';
  String _club = '7i';
  String _shotType = 'full_swing';
  String _lie = 'mat';
  String _intent = 'stock';
  String? _lastEventId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _targetController.dispose();
    _holeController.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    setState(() => _busy = true);
    try {
      await widget.apiClient.health();
      final sensorJson = await widget.apiClient.currentSensors();
      final proxyJson = await widget.apiClient.proxyStatus();
      setState(() {
        _connection = const ApiConnectionState(
          online: true,
          label: 'Pi API online',
          detail: RailGolfApp.apiBaseUrl,
        );
        _sensors = SensorSnapshot.fromJson(sensorJson);
        _proxyStatus = ProxyStatus.fromJson(proxyJson);
      });
    } catch (error) {
      setState(() {
        _connection = ApiConnectionState(
          online: false,
          label: 'Pi API offline',
          detail: error.toString(),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _startSession() async {
    setState(() => _busy = true);
    try {
      final json = await widget.apiClient.startSession(
        mode: _mode,
        locationLabel: _locationController.text,
      );
      setState(() {
        _activeSession = GolfSession.fromJson(json);
        _lastEventId = null;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _stopSession() async {
    final session = _activeSession;
    if (session == null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.apiClient.stopSession(session.id);
      setState(() {
        _activeSession = null;
        _lastEventId = null;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _stageShot() async {
    final session = _activeSession;
    if (session == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      final json = await widget.apiClient.createSwingEvent(
        session.id,
        club: _club,
        shotType: _shotType,
        targetDistance: double.tryParse(_targetController.text),
        intentTag: _intent,
        holeNumber: int.tryParse(_holeController.text),
        lie: _lie,
      );
      setState(() {
        _lastEventId = json['id'] as String?;
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _activeSession;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(
                connection: _connection,
                busy: _busy,
                onRefresh: _refreshStatus,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    final content = [
                      Expanded(
                        flex: 3,
                        child: _SessionPanel(
                          mode: _mode,
                          locationController: _locationController,
                          activeSession: session,
                          onModeChanged: (value) =>
                              setState(() => _mode = value),
                          onStart: _busy ? null : _startSession,
                          onStop: _busy ? null : _stopSession,
                        ),
                      ),
                      const SizedBox(width: 16, height: 16),
                      Expanded(
                        flex: 4,
                        child: _ShotPanel(
                          enabled: session != null && !_busy,
                          club: _club,
                          shotType: _shotType,
                          lie: _lie,
                          intent: _intent,
                          targetController: _targetController,
                          holeController: _holeController,
                          lastEventId: _lastEventId,
                          onClubChanged: (value) =>
                              setState(() => _club = value),
                          onShotTypeChanged: (value) =>
                              setState(() => _shotType = value),
                          onLieChanged: (value) => setState(() => _lie = value),
                          onIntentChanged: (value) =>
                              setState(() => _intent = value),
                          onStageShot: _stageShot,
                        ),
                      ),
                      const SizedBox(width: 16, height: 16),
                      Expanded(
                        flex: 3,
                        child: _LivePanel(
                          sensors: _sensors,
                          proxyStatus: _proxyStatus,
                          session: session,
                        ),
                      ),
                    ];

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: content,
                      );
                    }

                    return ListView(
                      children: content
                          .map(
                            (widget) => widget is Expanded
                                ? SizedBox(height: 320, child: widget.child)
                                : widget,
                          )
                          .toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.connection,
    required this.busy,
    required this.onRefresh,
  });

  final ApiConnectionState connection;
  final bool busy;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final color = connection.online ? Colors.lightGreenAccent : Colors.orange;
    return Row(
      children: [
        const Icon(Icons.sports_golf, size: 34),
        const SizedBox(width: 12),
        const Text(
          'Rail Golf',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Icon(Icons.circle, color: color, size: 14),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            connection.label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          tooltip: 'Refresh',
          onPressed: busy ? null : onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _SessionPanel extends StatelessWidget {
  const _SessionPanel({
    required this.mode,
    required this.locationController,
    required this.activeSession,
    required this.onModeChanged,
    required this.onStart,
    required this.onStop,
  });

  final String mode;
  final TextEditingController locationController;
  final GolfSession? activeSession;
  final ValueChanged<String> onModeChanged;
  final VoidCallback? onStart;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final active = activeSession != null;
    return _Panel(
      title: 'Session',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'practice', label: Text('Practice')),
              ButtonSegment(value: 'round', label: Text('Round')),
            ],
            selected: {mode},
            onSelectionChanged:
                active ? null : (selected) => onModeChanged(selected.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: locationController,
            enabled: !active,
            decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.place_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const Spacer(),
          _StatusRow(
            label: 'State',
            value: active ? activeSession!.status : 'idle',
          ),
          _StatusRow(
            label: 'Session',
            value: active ? activeSession!.id.substring(0, 8) : 'none',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: active ? onStop : onStart,
            icon: Icon(active ? Icons.stop : Icons.play_arrow),
            label: Text(active ? 'Stop Session' : 'Start Session'),
          ),
        ],
      ),
    );
  }
}

class _ShotPanel extends StatelessWidget {
  const _ShotPanel({
    required this.enabled,
    required this.club,
    required this.shotType,
    required this.lie,
    required this.intent,
    required this.targetController,
    required this.holeController,
    required this.lastEventId,
    required this.onClubChanged,
    required this.onShotTypeChanged,
    required this.onLieChanged,
    required this.onIntentChanged,
    required this.onStageShot,
  });

  final bool enabled;
  final String club;
  final String shotType;
  final String lie;
  final String intent;
  final TextEditingController targetController;
  final TextEditingController holeController;
  final String? lastEventId;
  final ValueChanged<String> onClubChanged;
  final ValueChanged<String> onShotTypeChanged;
  final ValueChanged<String> onLieChanged;
  final ValueChanged<String> onIntentChanged;
  final VoidCallback onStageShot;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Shot Setup',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _ChoiceField(
                  label: 'Club',
                  value: club,
                  values: const [
                    'Dr',
                    '3w',
                    '5w',
                    '4i',
                    '5i',
                    '6i',
                    '7i',
                    '8i',
                    '9i',
                    'PW',
                    'SW',
                  ],
                  enabled: enabled,
                  onChanged: onClubChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceField(
                  label: 'Shot',
                  value: shotType,
                  values: const ['full_swing', 'chip', 'pitch', 'putt'],
                  enabled: enabled,
                  onChanged: onShotTypeChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: targetController,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target yards',
                    prefixIcon: Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: holeController,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Hole',
                    prefixIcon: Icon(Icons.pin_drop_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ChoiceField(
                  label: 'Lie',
                  value: lie,
                  values: const ['mat', 'tee', 'fairway', 'rough', 'sand'],
                  enabled: enabled,
                  onChanged: onLieChanged,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChoiceField(
                  label: 'Intent',
                  value: intent,
                  values: const ['stock', 'draw', 'fade', 'knockdown', 'layup'],
                  enabled: enabled,
                  onChanged: onIntentChanged,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (lastEventId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StatusRow(
                label: 'Open event',
                value: lastEventId!.substring(0, 8),
              ),
            ),
          FilledButton.icon(
            onPressed: enabled ? onStageShot : null,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Stage Next Shot'),
          ),
        ],
      ),
    );
  }
}

class _LivePanel extends StatelessWidget {
  const _LivePanel({
    required this.sensors,
    required this.proxyStatus,
    required this.session,
  });

  final SensorSnapshot? sensors;
  final ProxyStatus? proxyStatus;
  final GolfSession? session;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Live Edge',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricTile(
            icon: Icons.thermostat,
            label: 'Temperature',
            value: sensors?.temperatureC == null
                ? '--'
                : '${sensors!.temperatureC!.toStringAsFixed(1)} C',
          ),
          const SizedBox(height: 10),
          _MetricTile(
            icon: Icons.water_drop_outlined,
            label: 'Humidity',
            value: sensors?.humidityPct == null
                ? '--'
                : '${sensors!.humidityPct!.toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 10),
          _MetricTile(
            icon: Icons.speed,
            label: 'Pressure',
            value: sensors?.pressureHpa == null
                ? '--'
                : '${sensors!.pressureHpa!.toStringAsFixed(0)} hPa',
          ),
          const Spacer(),
          _IntegrationChip(
            icon: Icons.router,
            label: 'Mevo proxy',
            active: proxyStatus?.mevoConnected == true,
            detail: proxyStatus?.status,
          ),
          const SizedBox(height: 8),
          _IntegrationChip(
            icon: Icons.memory,
            label: 'MCU bus',
            active: false,
          ),
          const SizedBox(height: 8),
          _IntegrationChip(
            icon: Icons.touch_app,
            label: 'FS Golf bridge',
            active: false,
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff18211c),
        border: Border.all(color: const Color(0xff2b3a30)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.values,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: enabled ? (value) => onChanged(value!) : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff101613),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _IntegrationChip extends StatelessWidget {
  const _IntegrationChip({
    required this.icon,
    required this.label,
    required this.active,
    this.detail,
  });

  final IconData icon;
  final String label;
  final bool active;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? Colors.lightGreenAccent : const Color(0xff3b463f),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              detail == null ? label : '$label: $detail',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: active ? Colors.lightGreenAccent : Colors.white54,
          ),
        ],
      ),
    );
  }
}
