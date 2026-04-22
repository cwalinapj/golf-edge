import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WalletUser {
  const WalletUser({
    required this.address,
    required this.chainId,
    required this.namespace,
    required this.connectedAt,
    this.guest = false,
  });

  final String address;
  final String chainId;
  final String namespace;
  final DateTime connectedAt;
  final bool guest;

  factory WalletUser.guest() {
    return WalletUser(
      address: 'guest',
      chainId: 'guest',
      namespace: 'guest',
      connectedAt: DateTime.now(),
      guest: true,
    );
  }

  bool get persistsBinding => !guest;

  String get storageKey => guest ? 'guest' : '$namespace.$address';

  String get shortAddress {
    if (guest) {
      return 'Guest';
    }
    if (address.length <= 12) {
      return address;
    }
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}

class WalletUserStore {
  static const _addressKey = 'wallet_user.address';
  static const _chainIdKey = 'wallet_user.chain_id';
  static const _namespaceKey = 'wallet_user.namespace';
  static const _connectedAtKey = 'wallet_user.connected_at';

  Future<WalletUser?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString(_addressKey);
    final chainId = prefs.getString(_chainIdKey);
    final namespace = prefs.getString(_namespaceKey);
    final connectedAtMillis = prefs.getInt(_connectedAtKey);

    if (address == null ||
        address.isEmpty ||
        chainId == null ||
        chainId.isEmpty ||
        namespace == null ||
        namespace.isEmpty ||
        connectedAtMillis == null) {
      return null;
    }

    return WalletUser(
      address: address,
      chainId: chainId,
      namespace: namespace,
      connectedAt: DateTime.fromMillisecondsSinceEpoch(connectedAtMillis),
    );
  }

  Future<void> save(WalletUser user) async {
    if (user.guest) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressKey, user.address);
    await prefs.setString(_chainIdKey, user.chainId);
    await prefs.setString(_namespaceKey, user.namespace);
    await prefs.setInt(
      _connectedAtKey,
      user.connectedAt.millisecondsSinceEpoch,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_addressKey);
    await prefs.remove(_chainIdKey);
    await prefs.remove(_namespaceKey);
    await prefs.remove(_connectedAtKey);
  }
}

class WalletUserScope extends InheritedWidget {
  const WalletUserScope({
    required this.user,
    required super.child,
    super.key,
  });

  final WalletUser user;

  static WalletUser of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WalletUserScope>();
    assert(scope != null, 'No WalletUserScope found in context.');
    return scope!.user;
  }

  static WalletUser? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WalletUserScope>()?.user;
  }

  @override
  bool updateShouldNotify(WalletUserScope oldWidget) {
    return user.address != oldWidget.user.address ||
        user.chainId != oldWidget.user.chainId ||
        user.namespace != oldWidget.user.namespace;
  }
}
