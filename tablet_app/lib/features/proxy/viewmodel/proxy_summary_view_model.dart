import '../../../core/model/models.dart';
import '../../../core/pi_api/api/pi_api_client.dart';

class ProxySummary {
  const ProxySummary({
    required this.piConnected,
    required this.proxyStatus,
  });

  final bool piConnected;
  final ProxyStatus? proxyStatus;
}

class ProxySummaryViewModel {
  const ProxySummaryViewModel({required PiApiClient piApiClient})
      : _piApiClient = piApiClient;

  final PiApiClient _piApiClient;

  Future<ProxySummary> load() async {
    final piConnected = await _piApiClient.isOnline();
    final status = ProxyStatus.fromJson(await _piApiClient.proxyStatus());
    return ProxySummary(piConnected: piConnected, proxyStatus: status);
  }
}
