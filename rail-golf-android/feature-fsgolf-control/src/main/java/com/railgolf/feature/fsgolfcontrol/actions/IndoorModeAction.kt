package com.railgolf.feature.fsgolfcontrol.actions

import com.railgolf.core.accessibility.bridge.AccessibilityFacade

class IndoorModeAction(private val accessibilityFacade: AccessibilityFacade) {
    fun run() = accessibilityFacade.runRecipe("set_indoor_mode")
}
