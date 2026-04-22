package com.railgolf.feature.dashboard.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.railgolf.core.ui.components.ActionButton
import com.railgolf.core.ui.components.InfoRow
import com.railgolf.core.ui.components.SectionHeader
import com.railgolf.feature.dashboard.model.DashboardState

@Composable
fun DashboardScreen(
    state: DashboardState,
    onOutdoorMode: () -> Unit,
    onIndoorMode: () -> Unit,
    onStartSession: () -> Unit,
) {
    Column {
        SectionHeader(text = "Rail Golf")
        InfoRow(label = "Pi connected", value = if (state.proxyStatus.piConnected) "Yes" else "No")
        InfoRow(label = "Proxy status", value = state.proxyStatus.state)
        InfoRow(label = "FS Golf current screen", value = state.fsGolfScreenState.label)
        Spacer(modifier = Modifier.height(16.dp))
        ActionButton(label = "Outdoor Mode", onClick = onOutdoorMode)
        ActionButton(label = "Indoor Mode", onClick = onIndoorMode)
        ActionButton(label = "Start Session", onClick = onStartSession)
    }
}
