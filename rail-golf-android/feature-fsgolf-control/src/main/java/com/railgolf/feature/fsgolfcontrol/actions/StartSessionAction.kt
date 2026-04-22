package com.railgolf.feature.fsgolfcontrol.actions

import com.railgolf.core.accessibility.bridge.AccessibilityFacade

class StartSessionAction(private val accessibilityFacade: AccessibilityFacade) {
    fun run() = accessibilityFacade.runRecipe("start_new_session")
}
