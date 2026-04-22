package com.railgolf.core.accessibility.executor

import com.railgolf.core.model.ActionResult

class ActionExecutor {
    fun execute(actionId: String): ActionResult {
        return ActionResult(ok = false, message = "Accessibility action pending: $actionId")
    }
}
