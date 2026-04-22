import '../../../core/accessibility/executor/fs_golf_recipe_executor.dart';
import '../../../core/accessibility/model/accessibility_action_result.dart';

class FsGolfActions {
  const FsGolfActions({required FsGolfRecipeExecutor executor})
      : _executor = executor;

  final FsGolfRecipeExecutor _executor;

  Future<AccessibilityActionResult> setOutdoorMode() {
    return _executor.runRecipe('set_outdoor_mode');
  }

  Future<AccessibilityActionResult> setIndoorMode() {
    return _executor.runRecipe('set_indoor_mode');
  }

  Future<AccessibilityActionResult> startSession() {
    return _executor.runRecipe('start_new_session');
  }

  Future<String> currentScreen() {
    return _executor.currentScreen();
  }
}
