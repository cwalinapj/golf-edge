package com.railgolf.core.accessibility.bridge

import com.railgolf.core.accessibility.executor.RecipeExecutor
import com.railgolf.core.accessibility.reader.ScreenReader
import com.railgolf.core.model.ActionResult
import com.railgolf.core.model.FsGolfScreenState

class AccessibilityFacade(
    private val recipeExecutor: RecipeExecutor = RecipeExecutor(),
    private val screenReader: ScreenReader = ScreenReader(),
) {
    fun currentScreen(): FsGolfScreenState = screenReader.currentScreen()

    fun runRecipe(recipeId: String): ActionResult = recipeExecutor.run(recipeId)
}
