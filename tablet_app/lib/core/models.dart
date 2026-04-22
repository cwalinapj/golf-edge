class ApiConnectionState {
  const ApiConnectionState({
    required this.online,
    required this.label,
    this.detail,
  });

  final bool online;
  final String label;
  final String? detail;
}

class GolfSession {
  const GolfSession({
    required this.id,
    required this.mode,
    required this.status,
    this.locationLabel,
  });

  factory GolfSession.fromJson(Map<String, dynamic> json) {
    return GolfSession(
      id: json['id'] as String,
      mode: json['mode'] as String,
      status: json['status'] as String,
      locationLabel: json['location_label'] as String?,
    );
  }

  final String id;
  final String mode;
  final String status;
  final String? locationLabel;
}

class SensorSnapshot {
  const SensorSnapshot({
    required this.capturedAt,
    this.temperatureC,
    this.humidityPct,
    this.pressureHpa,
  });

  factory SensorSnapshot.fromJson(Map<String, dynamic> json) {
    return SensorSnapshot(
      capturedAt: DateTime.parse(json['captured_at'] as String),
      temperatureC: (json['temperature_c'] as num?)?.toDouble(),
      humidityPct: (json['humidity_pct'] as num?)?.toDouble(),
      pressureHpa: (json['pressure_hpa'] as num?)?.toDouble(),
    );
  }

  final DateTime capturedAt;
  final double? temperatureC;
  final double? humidityPct;
  final double? pressureHpa;
}

class ProxyStatus {
  const ProxyStatus({
    required this.status,
    required this.mevoConnected,
    required this.clientConnected,
    required this.packetsSeen,
    this.openPorts = const [],
    this.mevoIp,
    this.detail,
  });

  factory ProxyStatus.fromJson(Map<String, dynamic> json) {
    return ProxyStatus(
      status: json['status'] as String,
      mevoConnected: json['mevo_connected'] as bool? ?? false,
      clientConnected: json['client_connected'] as bool? ?? false,
      packetsSeen: json['packets_seen'] as int? ?? 0,
      openPorts: (json['open_ports'] as List<dynamic>? ?? const [])
          .whereType<int>()
          .toList(),
      mevoIp: json['mevo_ip'] as String?,
      detail: json['detail'] as String?,
    );
  }

  final String status;
  final bool mevoConnected;
  final bool clientConnected;
  final int packetsSeen;
  final List<int> openPorts;
  final String? mevoIp;
  final String? detail;
}
