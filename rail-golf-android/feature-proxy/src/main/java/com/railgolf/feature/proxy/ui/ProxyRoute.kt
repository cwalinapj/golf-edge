package com.railgolf.feature.proxy.ui

import androidx.compose.runtime.Composable
import com.railgolf.feature.proxy.viewmodel.ProxyViewModel

@Composable
fun ProxyRoute(viewModel: ProxyViewModel) {
    ProxyScreen(
        status = viewModel.status(),
        onStartProxy = viewModel::startProxy,
        onStopProxy = viewModel::stopProxy,
        onRefreshStatus = viewModel::refreshStatus,
        onViewDiscoveryResponse = viewModel::viewDiscoveryResponse,
    )
}
