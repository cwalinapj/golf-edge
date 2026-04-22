package com.railgolf.feature.fsgolfcontrol.viewmodel

import com.railgolf.core.accessibility.bridge.AccessibilityFacade
import com.railgolf.core.model.FsGolfScreenState
import com.railgolf.feature.fsgolfcontrol.actions.IndoorModeAction
import com.railgolf.feature.fsgolfcontrol.actions.OutdoorModeAction
import com.railgolf.feature.fsgolfcontrol.actions.StartSessionAction

class FsGolfControlViewModel(private val accessibilityFacade: AccessibilityFacade) {
    fun screenState(): FsGolfScreenState = accessibilityFacade.currentScreen()

    fun outdoorMode() = OutdoorModeAction(accessibilityFacade).run()

    fun indoorMode() = IndoorModeAction(accessibilityFacade).run()

    fun startSession() = StartSessionAction(accessibilityFacade).run()

    fun back() = accessibilityFacade.runRecipe("back")

    fun openRadarAdjustment() = accessibilityFacade.runRecipe("open_radar_adjustment")
}
