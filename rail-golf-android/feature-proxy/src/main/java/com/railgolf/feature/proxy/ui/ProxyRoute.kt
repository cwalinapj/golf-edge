package com.railgolf.feature.proxy.ui

import androidx.compose.runtime.Composable
import com.railgolf.feature.proxy.viewmodel.ProxyViewModel

@Composable
fun ProxyRoute(viewModel: ProxyViewModel) {
    ProxyScreen(status = viewModel.status())
}
