import 'package:flutter/material.dart';

import '../../../core/accessibility/model/accessibility_action_result.dart';
import '../../../core/model/models.dart';
import '../../../core/pi_api/api/pi_api_client.dart';
import '../../fsgolf_control/actions/fs_golf_actions.dart';
import '../../proxy/viewmodel/proxy_summary_view_model.dart';

class MinimalDashboardScreen extends StatefulWidget {
  const MinimalDashboardScreen({
    required this.piApiClient,
    required this.fsGolfActions,
    super.key,
  });

  final PiApiClient piApiClient;
  final FsGolfActions fsGolfActions;

  @override
  State<MinimalDashboardScreen> createState() => _MinimalDashboardScreenState();
}

class _MinimalDashboardScreenState extends State<MinimalDashboardScreen> {
  bool _loading = true;
  bool _runningAction = false;
  bool _piConnected = false;
  ProxyStatus? _proxyStatus;
  String _fsGolfScreen = 'Checking FS Golf';
  String? _lastAction;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final proxySummary = await ProxySummaryViewModel(
        piApiClient: widget.piApiClient,
      ).load();
      final screen = await widget.fsGolfActions.currentScreen();
      if (!mounted) {
        return;
      }
      setState(() {
        _piConnected = proxySummary.piConnected;
        _proxyStatus = proxySummary.proxyStatus;
        _fsGolfScreen = screen;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _piConnected = false;
        _lastAction = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _runFsGolfAction(
    String label,
    Future<AccessibilityActionResult> Function() action,
  ) async {
    setState(() {
      _runningAction = true;
      _lastAction = '$label...';
    });
    try {
      final result = await action();
      if (!mounted) {
        return;
      }
      setState(() {
        _lastAction = result.message;
        if (result.screenLabel != null) {
          _fsGolfScreen = result.screenLabel!;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _runningAction = false);
      }
    }
  }

  Future<void> _startSession() async {
    setState(() {
      _runningAction = true;
      _lastAction = 'Starting session...';
    });
    try {
      await widget.piApiClient.startPracticeSession();
      final result = await widget.fsGolfActions.startSession();
      if (!mounted) {
        return;
      }
      setState(() {
        _lastAction = result.message;
        if (result.screenLabel != null) {
          _fsGolfScreen = result.screenLabel!;
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() => _lastAction = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _runningAction = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proxyStatus = _proxyStatus;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Icon(Icons.sports_golf, size: 34),
              const SizedBox(width: 12),
              const Text(
                'Rail Golf',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: 'Refresh',
                onPressed: _loading ? null : _refresh,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _StatusPanel(
            children: [
              _StatusLine(
                icon: Icons.router_outlined,
                label: 'Pi connected',
                value: _piConnected ? 'Online' : 'Offline',
                active: _piConnected,
              ),
              _StatusLine(
                icon: Icons.route_outlined,
                label: 'Proxy status',
                value: proxyStatus == null
                    ? 'Unknown'
                    : '${proxyStatus.status} (${proxyStatus.openPorts.join(', ')})',
                active: proxyStatus?.mevoConnected == true,
              ),
              _StatusLine(
                icon: Icons.touch_app_outlined,
                label: 'FS Golf current screen',
                value: _fsGolfScreen,
                active: !_fsGolfScreen.toLowerCase().contains('unavailable'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ActionGrid(
            enabled: !_runningAction,
            onOutdoor: () => _runFsGolfAction(
              'Outdoor Mode',
              widget.fsGolfActions.setOutdoorMode,
            ),
            onIndoor: () => _runFsGolfAction(
              'Indoor Mode',
              widget.fsGolfActions.setIndoorMode,
            ),
            onStartSession: _startSession,
          ),
          if (_lastAction != null) ...[
            const SizedBox(height: 16),
            _MessagePanel(message: _lastAction!),
          ],
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff18211c),
        border: Border.all(color: const Color(0xff2b3a30)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: children),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.active,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: active ? Colors.lightGreenAccent : Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.enabled,
    required this.onOutdoor,
    required this.onIndoor,
    required this.onStartSession,
  });

  final bool enabled;
  final VoidCallback onOutdoor;
  final VoidCallback onIndoor;
  final VoidCallback onStartSession;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ActionButton(
          icon: Icons.wb_sunny_outlined,
          label: 'Outdoor Mode',
          enabled: enabled,
          onPressed: onOutdoor,
        ),
        _ActionButton(
          icon: Icons.home_outlined,
          label: 'Indoor Mode',
          enabled: enabled,
          onPressed: onIndoor,
        ),
        _ActionButton(
          icon: Icons.play_arrow,
          label: 'Start Session',
          enabled: enabled,
          onPressed: onStartSession,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 54,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff111a15),
        border: Border.all(color: const Color(0xff2b3a30)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white70)),
    );
  }
}
