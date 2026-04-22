class AccessibilityActionResult {
  const AccessibilityActionResult({
    required this.ok,
    required this.message,
    this.screenLabel,
  });

  factory AccessibilityActionResult.fromJson(Map<dynamic, dynamic> json) {
    return AccessibilityActionResult(
      ok: json['ok'] == true,
      message: json['message'] as String? ?? 'No accessibility response.',
      screenLabel: json['screen_label'] as String?,
    );
  }

  final bool ok;
  final String message;
  final String? screenLabel;
}
