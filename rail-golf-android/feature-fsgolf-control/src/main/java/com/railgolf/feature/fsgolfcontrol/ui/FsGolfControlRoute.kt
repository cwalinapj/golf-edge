package com.railgolf.feature.fsgolfcontrol.ui

import androidx.compose.runtime.Composable
import com.railgolf.feature.fsgolfcontrol.viewmodel.FsGolfControlViewModel

@Composable
fun FsGolfControlRoute(viewModel: FsGolfControlViewModel) {
    FsGolfControlScreen(
        screenState = viewModel.screenState(),
        onOutdoorMode = viewModel::outdoorMode,
        onIndoorMode = viewModel::indoorMode,
        onStartSession = viewModel::startSession,
        onBack = viewModel::back,
        onOpenRadarAdjustment = viewModel::openRadarAdjustment,
    )
}
