package com.railgolf.feature.dashboard.ui

import androidx.compose.runtime.Composable
import com.railgolf.core.accessibility.bridge.AccessibilityFacade
import com.railgolf.core.common.RailGolfConstants
import com.railgolf.core.piapi.api.PiApiService
import com.railgolf.core.piapi.repository.PiRepository
import com.railgolf.feature.dashboard.viewmodel.DashboardViewModel

@Composable
fun DashboardRoute() {
    val viewModel = DashboardViewModel(
        piRepository = PiRepository(
            apiService = PiApiService(baseUrl = RailGolfConstants.DefaultPiBaseUrl),
        ),
        accessibilityFacade = AccessibilityFacade(),
    )
    DashboardScreen(
        state = viewModel.state(),
        onOutdoorMode = viewModel::outdoorMode,
        onIndoorMode = viewModel::indoorMode,
        onStartSession = viewModel::startSession,
    )
}
