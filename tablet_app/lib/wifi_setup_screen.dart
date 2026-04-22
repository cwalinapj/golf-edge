import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/wifi_scan_channel.dart';

class WifiSetupScreen extends StatefulWidget {
  const WifiSetupScreen({super.key, WifiScanChannel? channel})
      : channel = channel ?? const _DefaultWifiScanChannel();

  final WifiScanChannel channel;

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  final _passphraseController = TextEditingController();
  List<WifiNetwork> _networks = const [];
  WifiNetwork? _selected;
  String? _status;
  bool _scanning = false;
  bool _saving = false;

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _status = null;
    });

    try {
      final networks = await widget.channel.scan();
      setState(() {
        _networks = networks;
        final previous = _selected;
        WifiNetwork? nextSelected;
        for (final network in networks) {
          if (network.bssid == previous?.bssid) {
            nextSelected = network;
            break;
          }
        }
        _selected = nextSelected ?? (networks.isEmpty ? null : networks.first);
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
    if (selected == null) {
      return;
    }

    setState(() {
      _saving = true;
      _status = null;
    });

    try {
      await widget.channel.saveBinding(
        WifiBinding(
          ssid: selected.ssid,
          bssid: selected.bssid,
          capabilities: selected.capabilities,
          passphrase: _passphraseController.text,
        ),
      );
      setState(() => _status = 'Saved ${selected.ssid}');
    } catch (error) {
      setState(() => _status = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _friendlyError(Object error) {
    if (error is PlatformException) {
      return error.message ?? error.code;
    }
    return error.toString();
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
            passphraseController: _passphraseController,
            saving: _saving,
            status: _status,
            onSave: selected == null || _saving ? null : _save,
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: list),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: details),
              ],
            );
          }

          return ListView(
            children: [
              SizedBox(height: 420, child: list),
              const SizedBox(height: 16),
              SizedBox(height: 360, child: details),
            ],
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
      title: 'Mevo Wi-Fi',
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
                    network.secured ? Icons.wifi_lock : Icons.wifi,
                    color: active ? Colors.lightGreenAccent : null,
                  ),
                  title: Text(
                    network.ssid,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${network.band}  ${network.bssid}'),
                  trailing: Text('${network.level} dBm'),
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
    required this.passphraseController,
    required this.saving,
    required this.status,
    required this.onSave,
  });

  final WifiNetwork? selected;
  final TextEditingController passphraseController;
  final bool saving;
  final String? status;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Binding',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldRow(label: 'SSID', value: selected?.ssid ?? 'none'),
          _FieldRow(label: 'BSSID', value: selected?.bssid ?? 'none'),
          _FieldRow(label: 'Security', value: selected?.capabilities ?? 'none'),
          const SizedBox(height: 18),
          TextField(
            controller: passphraseController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Passphrase',
              prefixIcon: Icon(Icons.key),
              border: OutlineInputBorder(),
            ),
          ),
          const Spacer(),
          if (status != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child:
                  Text(status!, style: const TextStyle(color: Colors.white70)),
            ),
          FilledButton.icon(
            onPressed: onSave,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
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
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
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
  const _Panel({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

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
          Row(
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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

class _DefaultWifiScanChannel extends WifiScanChannel {
  const _DefaultWifiScanChannel();
}
