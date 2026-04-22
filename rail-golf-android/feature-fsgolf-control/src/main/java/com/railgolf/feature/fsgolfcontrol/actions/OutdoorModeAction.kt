package com.railgolf.feature.fsgolfcontrol.actions

import com.railgolf.core.accessibility.bridge.AccessibilityFacade

class OutdoorModeAction(private val accessibilityFacade: AccessibilityFacade) {
    fun run() = accessibilityFacade.runRecipe("set_outdoor_mode")
}
