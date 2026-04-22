package com.railgolf.feature.proxy.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import com.railgolf.core.model.ProxyStatus
import com.railgolf.core.ui.components.ActionButton
import com.railgolf.core.ui.components.InfoRow
import com.railgolf.core.ui.components.SectionHeader

@Composable
fun ProxyScreen(
    status: ProxyStatus,
    onStartProxy: () -> Unit,
    onStopProxy: () -> Unit,
    onRefreshStatus: () -> Unit,
    onViewDiscoveryResponse: () -> Unit,
) {
    Column {
        SectionHeader(text = "Proxy")
        InfoRow(label = "State", value = status.state)
        InfoRow(label = "Mevo", value = if (status.mevoConnected) "available" else "not discovered")
        InfoRow(label = "TCP 5100", value = if (status.tcp5100Connected) "connected" else "closed")
        InfoRow(label = "TCP 1258", value = if (status.tcp1258Connected) "connected" else "closed")
        ActionButton(label = "Start Proxy", onClick = onStartProxy)
        ActionButton(label = "Stop Proxy", onClick = onStopProxy)
        ActionButton(label = "Refresh Status", onClick = onRefreshStatus)
        ActionButton(label = "View discovery response", onClick = onViewDiscoveryResponse)
    }
}
