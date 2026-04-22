import 'package:shared_preferences/shared_preferences.dart';

import 'wallet_user.dart';
import 'wifi_scan_channel.dart';

class SavedMevoBinding {
  const SavedMevoBinding({
    required this.ssid,
    required this.bssid,
    required this.capabilities,
    required this.savedAt,
  });

  final String ssid;
  final String bssid;
  final String capabilities;
  final DateTime savedAt;
}

class MevoBindingStore {
  String _prefix(WalletUser user) => 'mevo_binding.${user.storageKey}';

  Future<SavedMevoBinding?> load(WalletUser user) async {
    if (!user.persistsBinding) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final prefix = _prefix(user);
    final ssid = prefs.getString('$prefix.ssid');
    final bssid = prefs.getString('$prefix.bssid');
    final capabilities = prefs.getString('$prefix.capabilities');
    final savedAtMillis = prefs.getInt('$prefix.saved_at');

    if (ssid == null ||
        ssid.isEmpty ||
        bssid == null ||
        bssid.isEmpty ||
        savedAtMillis == null) {
      return null;
    }

    return SavedMevoBinding(
      ssid: ssid,
      bssid: bssid,
      capabilities: capabilities ?? '',
      savedAt: DateTime.fromMillisecondsSinceEpoch(savedAtMillis),
    );
  }

  Future<void> save(WalletUser user, WifiBinding binding) async {
    if (!user.persistsBinding) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final prefix = _prefix(user);
    await prefs.setString('$prefix.ssid', binding.ssid);
    await prefs.setString('$prefix.bssid', binding.bssid);
    await prefs.setString('$prefix.capabilities', binding.capabilities);
    await prefs.setInt(
      '$prefix.saved_at',
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
