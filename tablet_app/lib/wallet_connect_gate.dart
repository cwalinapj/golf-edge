import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';

import 'core/admin_wifi_channel.dart';
import 'core/api_client.dart';
import 'core/wallet_user.dart';

class WalletConnectGate extends StatefulWidget {
  const WalletConnectGate({
    required this.onConnected,
    required this.onGuest,
    this.apiClient,
    this.adminWifiChannel = const AdminWifiChannel(),
    super.key,
  });

  final ValueChanged<WalletUser> onConnected;
  final VoidCallback onGuest;
  final ApiClient? apiClient;
  final AdminWifiChannel adminWifiChannel;

  @override
  State<WalletConnectGate> createState() => _WalletConnectGateState();
}

class _WalletConnectGateState extends State<WalletConnectGate> {
  static const _projectId = String.fromEnvironment('REOWN_PROJECT_ID');

  ReownAppKitModal? _appKitModal;
  bool _ready = false;
  bool _openingAdmin = false;
  String? _status;

  @override
  void initState() {
    super.initState();

    if (_projectId.isEmpty) {
      _status = 'WalletConnect setup is pending.';
      return;
    }

    _appKitModal = ReownAppKitModal(
      context: context,
      projectId: _projectId,
      metadata: const PairingMetadata(
        name: 'Rail Golf',
        description: 'Rail Golf launch monitor UI',
        url: 'https://rail-golf.local/',
        icons: ['https://reown.com/logo.png'],
        redirect: Redirect(
          native: 'golfedge://walletconnect',
          universal: 'https://rail-golf.local/walletconnect',
        ),
      ),
      optionalNamespaces: _supportedNamespaces(),
      disconnectOnDispose: false,
    );

    _appKitModal!.onModalConnect.subscribe(_handleConnect);
    _appKitModal!.onModalDisconnect.subscribe(_handleDisconnect);
    _appKitModal!.onModalError.subscribe(_handleError);
    _initModal();
  }

  @override
  void dispose() {
    final modal = _appKitModal;
    modal?.onModalConnect.unsubscribe(_handleConnect);
    modal?.onModalDisconnect.unsubscribe(_handleDisconnect);
    modal?.onModalError.unsubscribe(_handleError);
    modal?.dispose();
    super.dispose();
  }

  Future<void> _initModal() async {
    try {
      await _appKitModal!.init();
      if (!mounted) {
        return;
      }
      setState(() => _ready = true);
      _syncConnectedSession();
    } catch (error) {
      if (mounted) {
        setState(() => _status = 'WalletConnect unavailable: $error');
      }
    }
  }

  void _handleConnect(ModalConnect? event) {
    _syncConnectedSession();
  }

  void _handleDisconnect(ModalDisconnect? event) {
    if (mounted) {
      setState(() => _status = 'Wallet disconnected.');
    }
  }

  void _handleError(ModalError? event) {
    if (mounted) {
      setState(() => _status = event?.message ?? 'WalletConnect failed.');
    }
  }

  void _syncConnectedSession() {
    final modal = _appKitModal;
    final chainId = modal?.selectedChain?.chainId;
    if (modal == null || !modal.isConnected || chainId == null) {
      return;
    }

    final namespace = NamespaceUtils.getNamespaceFromChain(chainId);
    final address = modal.session?.getAddress(namespace);
    if (address == null || address.isEmpty) {
      setState(() => _status = 'Connected wallet did not return an address.');
      return;
    }

    widget.onConnected(
      WalletUser(
        address: address,
        chainId: chainId,
        namespace: namespace,
        connectedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _openAdminSetup() async {
    setState(() {
      _openingAdmin = true;
      _status = 'Opening Rail Golf setup network...';
    });

    try {
      await _apiClient.openSetupAp();
    } catch (_) {
      // The Pi may already be in setup AP mode, or the phone may not be on a
      // network that can reach the Pi yet. Still try joining the default AP.
    }

    try {
      await widget.adminWifiChannel.connectSetupAp();
      if (mounted) {
        setState(() => _status = 'Connected to Rail Golf setup network.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _status = 'Setup network unavailable: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _openingAdmin = false);
      }
    }
  }

  ApiClient get _apiClient {
    return widget.apiClient ??
        ApiClient(
          baseUrl: const String.fromEnvironment(
            'RAIL_GOLF_API_BASE_URL',
            defaultValue: 'http://10.42.0.1:8000',
          ),
        );
  }

  static Map<String, RequiredNamespace> _supportedNamespaces() {
    final namespaces = <String, RequiredNamespace>{};
    for (final namespace
        in ReownAppKitModalNetworks.getAllSupportedNamespaces()) {
      final chains = ReownAppKitModalNetworks.getAllSupportedNetworks(
        namespace: namespace,
      );
      if (chains.isEmpty) {
        continue;
      }
      namespaces[namespace] = RequiredNamespace(
        chains: chains.map((chain) => chain.chainId).toList(),
        methods: NetworkUtils.defaultNetworkMethods[namespace] ?? const [],
        events: NetworkUtils.defaultNetworkEvents[namespace] ?? const [],
      );
    }
    return namespaces;
  }

  @override
  Widget build(BuildContext context) {
    final modal = _appKitModal;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'Configuration',
                onPressed: _openingAdmin ? null : _openAdminSetup,
                icon: _openingAdmin
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.settings_outlined),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.asset(
                            'assets/images/rail_golf_logo.png',
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Welcome',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please login with your web 3.0 wallet or as a guest.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 28),
                      if (modal != null && _ready)
                        AppKitModalConnectButton(
                          appKit: modal,
                          context: context,
                        )
                      else
                        FilledButton.icon(
                          onPressed: null,
                          icon:
                              const Icon(Icons.account_balance_wallet_outlined),
                          label: Text(
                            _projectId.isEmpty
                                ? 'WalletConnect pending'
                                : 'Preparing',
                          ),
                        ),
                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: widget.onGuest,
                        icon: const Icon(Icons.person_outline),
                        label: const Text('Login as guest'),
                      ),
                      if (_status != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _status!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
