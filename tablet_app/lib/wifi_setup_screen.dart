import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/api_client.dart';
import 'core/mevo_binding_store.dart';
import 'core/wallet_user.dart';
import 'core/wifi_scan_channel.dart';

class WifiSetupScreen extends StatefulWidget {
  const WifiSetupScreen({
    super.key,
    this.apiClient,
    this.channel,
  });

  final WifiScanChannel? channel;
  final ApiClient? apiClient;

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  final _bindingStore = MevoBindingStore();
  final _passphraseController = TextEditingController();
  List<WifiNetwork> _networks = const [];
  WifiNetwork? _selected;
  SavedMevoBinding? _savedBinding;
  String? _status;
  bool _showPassphrase = false;
  bool _scanning = false;
  bool _saving = false;
  bool _continuing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSavedBinding();
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _status = 'Scanning through Rail Golf Controller...';
    });

    try {
      final networks = await _scanChannel.scan();
      setState(() {
        _networks = networks;
        _selected = null;
        _status = networks.isEmpty
            ? 'No networks returned'
            : 'Found ${networks.length} networks';
      });
    } catch (error) {
      setState(() => _status = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  Future<void> _save() async {
    final selected = _selected;
    final user = WalletUserScope.of(context);
    if (selected == null) {
      return;
    }

    setState(() {
      _saving = true;
      _status = 'Connecting ESP32 to ${selected.ssid}...';
    });

    try {
      final binding = WifiBinding(
        ssid: selected.ssid,
        bssid: selected.bssid,
        capabilities: selected.capabilities,
        passphrase: _passphraseController.text,
        ownerKey: user.storageKey,
        persist: user.persistsBinding,
      );
      final response = await _apiClient.bindLaunchMonitor(
        ssid: binding.ssid,
        bssid: binding.bssid,
        capabilities: binding.capabilities,
        passphrase: binding.passphrase,
        ownerKey: binding.ownerKey,
        stationInterface: 'eth1',
        keepConnected: true,
      );
      if (response['connected'] != true) {
        throw ApiClientException(
          response['detail'] as String? ?? 'Wrong passcode please try again.',
        );
      }

      await _bindingStore.save(user, binding);
      final savedBinding = await _bindingStore.load(user) ??
          SavedMevoBinding(
            ssid: binding.ssid,
            bssid: binding.bssid,
            capabilities: binding.capabilities,
            savedAt: DateTime.now(),
          );
      setState(() {
        _savedBinding = savedBinding;
        _status = user.persistsBinding
            ? 'ESP32 connected and saved ${selected.ssid}'
            : 'ESP32 connected for this guest session';
      });
    } catch (error) {
      setState(() => _status = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _continueToPi() async {
    final selected = _selected;
    final savedBinding = _savedBinding;
    if (selected == null ||
        savedBinding == null ||
        savedBinding.bssid != selected.bssid) {
      return;
    }

    setState(() {
      _continuing = true;
      _status = 'Launch monitor already connected. Controller handoff is next.';
    });

    try {
      setState(() => _status = 'Ready for controller handoff.');
    } catch (error) {
      setState(() => _status = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _continuing = false);
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

  WifiScanChannel get _scanChannel {
    return widget.channel ?? PiWifiScanChannel(_apiClient);
  }

  String _friendlyError(Object error) {
    if (error is PlatformException) {
      return error.message ?? error.code;
    }
    return error.toString();
  }

  Future<void> _loadSavedBinding() async {
    final user = WalletUserScope.of(context);
    final savedBinding = await _bindingStore.load(user);
    if (mounted) {
      setState(() => _savedBinding = savedBinding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          final list = _NetworkList(
            networks: _networks,
            selected: selected,
            scanning: _scanning,
            onScan: _scan,
            onSelected: (network) => setState(() => _selected = network),
          );
          final details = _BindingPanel(
            selected: selected,
            savedBinding: _savedBinding,
            passphraseController: _passphraseController,
            isSaved: _savedBinding?.bssid == selected?.bssid,
            showPassphrase: _showPassphrase,
            onTogglePassphrase: () {
              setState(() => _showPassphrase = !_showPassphrase);
            },
            saving: _saving,
            continuing: _continuing,
            status: _status,
            onSave: selected == null || _saving ? null : _save,
            onContinue: _savedBinding?.bssid == selected?.bssid && !_continuing
                ? _continueToPi
                : null,
          );

          if (selected != null) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SizedBox.expand(child: details),
              ),
            );
          }

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Expanded(child: list)],
            );
          }

          return ListView(
            children: [SizedBox(height: 420, child: list)],
          );
        },
      ),
    );
  }
}

class _NetworkList extends StatelessWidget {
  const _NetworkList({
    required this.networks,
    required this.selected,
    required this.scanning,
    required this.onScan,
    required this.onSelected,
  });

  final List<WifiNetwork> networks;
  final WifiNetwork? selected;
  final bool scanning;
  final VoidCallback onScan;
  final ValueChanged<WifiNetwork> onSelected;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Find Launch Monitor',
      action: FilledButton.icon(
        onPressed: scanning ? null : onScan,
        icon: scanning
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.wifi_find),
        label: const Text('Scan'),
      ),
      child: networks.isEmpty
          ? const Center(
              child: Text(
                'No scan results',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            )
          : ListView.separated(
              itemBuilder: (context, index) {
                final network = networks[index];
                final active = network.bssid == selected?.bssid;
                return ListTile(
                  selected: active,
                  selectedTileColor: Colors.lightGreen.withValues(alpha: 0.12),
                  leading: Icon(
                    network.isEthernetTarget
                        ? Icons.settings_ethernet
                        : network.secured
                            ? Icons.wifi_lock
                            : Icons.wifi,
                    color: active ? Colors.lightGreenAccent : null,
                  ),
                  title: Text(
                    network.ssid,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${network.transportLabel}  ${network.bssid}'),
                  trailing: network.isEthernetTarget
                      ? const Icon(Icons.lan)
                      : Text('${network.level} dBm'),
                  onTap: () => onSelected(network),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: networks.length,
            ),
    );
  }
}

class _BindingPanel extends StatelessWidget {
  const _BindingPanel({
    required this.selected,
    required this.savedBinding,
    required this.passphraseController,
    required this.isSaved,
    required this.showPassphrase,
    required this.onTogglePassphrase,
    required this.saving,
    required this.continuing,
    required this.status,
    required this.onSave,
    required this.onContinue,
  });

  final WifiNetwork? selected;
  final SavedMevoBinding? savedBinding;
  final TextEditingController passphraseController;
  final bool isSaved;
  final bool showPassphrase;
  final VoidCallback onTogglePassphrase;
  final bool saving;
  final bool continuing;
  final String? status;
  final VoidCallback? onSave;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Connect',
      centerTitle: true,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (savedBinding != null) ...[
                  _FieldRow(label: 'Saved', value: savedBinding!.ssid),
                  _FieldRow(label: 'BSSID', value: savedBinding!.bssid),
                  const SizedBox(height: 8),
                ],
                _FieldRow(label: 'Target', value: selected?.ssid ?? 'none'),
                _FieldRow(label: 'Address', value: selected?.bssid ?? 'none'),
                _FieldRow(
                  label: 'Transport',
                  value: selected?.capabilities ?? 'none',
                ),
                const SizedBox(height: 18),
                if (selected?.isEthernetTarget != true) ...[
                  TextField(
                    controller: passphraseController,
                    obscureText: !showPassphrase,
                    decoration: InputDecoration(
                      labelText: 'Passphrase',
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        tooltip: showPassphrase
                            ? 'Hide passphrase'
                            : 'Show passphrase',
                        onPressed: onTogglePassphrase,
                        icon: Icon(
                          showPassphrase
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                if (status != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      status!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: isSaved ? null : onSave,
                  style: isSaved
                      ? FilledButton.styleFrom(
                          disabledBackgroundColor: Colors.lightGreen,
                          disabledForegroundColor: Colors.black,
                        )
                      : null,
                  icon: saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(isSaved ? Icons.check_circle : Icons.link),
                  label: Text(isSaved ? 'Saved' : 'Connect'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onContinue,
                  icon: continuing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                  label: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 18),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.action,
    this.centerTitle = false,
  });

  final String title;
  final Widget child;
  final Widget? action;
  final bool centerTitle;

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
          if (centerTitle)
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (action != null) action!,
              ],
            ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}
