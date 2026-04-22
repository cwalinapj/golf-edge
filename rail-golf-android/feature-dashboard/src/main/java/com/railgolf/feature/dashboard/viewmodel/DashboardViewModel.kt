package com.railgolf.feature.dashboard.viewmodel

import com.railgolf.core.accessibility.bridge.AccessibilityFacade
import com.railgolf.core.piapi.repository.PiRepository
import com.railgolf.feature.dashboard.model.DashboardState

class DashboardViewModel(
    private val piRepository: PiRepository,
    private val accessibilityFacade: AccessibilityFacade,
) {
    fun state(): DashboardState {
        return DashboardState(
            proxyStatus = piRepository.proxyStatus(),
            fsGolfScreenState = accessibilityFacade.currentScreen(),
        )
    }

    fun outdoorMode() = accessibilityFacade.runRecipe("set_outdoor_mode")

    fun indoorMode() = accessibilityFacade.runRecipe("set_indoor_mode")

    fun startSession() = accessibilityFacade.runRecipe("start_new_session")
}
