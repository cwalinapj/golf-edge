package com.railgolf.core.accessibility.executor

import com.railgolf.core.model.ActionResult

class RecipeExecutor(private val actionExecutor: ActionExecutor = ActionExecutor()) {
    fun run(recipeId: String): ActionResult {
        return actionExecutor.execute(recipeId)
    }
}
