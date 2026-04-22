import 'package:flutter/services.dart';

import '../model/accessibility_action_result.dart';

class FsGolfRecipeExecutor {
  const FsGolfRecipeExecutor({
    MethodChannel channel = const MethodChannel('rail_golf/accessibility'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<String> currentScreen() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'currentScreen',
      );
      return result?['screen_label'] as String? ?? 'Unknown';
    } on MissingPluginException {
      return 'Accessibility service unavailable';
    } on PlatformException catch (error) {
      return error.message ?? error.code;
    }
  }

  Future<AccessibilityActionResult> runRecipe(String recipeId) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'runRecipe',
        <String, dynamic>{'recipe_id': recipeId},
      );
      if (result == null) {
        return const AccessibilityActionResult(
          ok: false,
          message: 'No accessibility response.',
        );
      }
      return AccessibilityActionResult.fromJson(result);
    } on MissingPluginException {
      return AccessibilityActionResult(
        ok: false,
        message: 'Accessibility service unavailable for $recipeId.',
      );
    } on PlatformException catch (error) {
      return AccessibilityActionResult(
        ok: false,
        message: error.message ?? error.code,
      );
    }
  }
}
