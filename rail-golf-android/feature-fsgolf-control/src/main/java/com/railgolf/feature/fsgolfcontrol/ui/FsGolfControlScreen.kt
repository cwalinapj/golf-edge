package com.railgolf.feature.fsgolfcontrol.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.runtime.Composable
import com.railgolf.core.model.FsGolfScreenState
import com.railgolf.core.ui.components.ActionButton
import com.railgolf.core.ui.components.InfoRow
import com.railgolf.core.ui.components.SectionHeader

@Composable
fun FsGolfControlScreen(
    screenState: FsGolfScreenState,
    onOutdoorMode: () -> Unit,
    onIndoorMode: () -> Unit,
    onStartSession: () -> Unit,
    onBack: () -> Unit,
    onOpenRadarAdjustment: () -> Unit,
) {
    Column {
        SectionHeader(text = "FS Golf")
        InfoRow(label = "Current screen", value = screenState.label)
        ActionButton(label = "Outdoor Mode", onClick = onOutdoorMode)
        ActionButton(label = "Indoor Mode", onClick = onIndoorMode)
        ActionButton(label = "Start Session", onClick = onStartSession)
        ActionButton(label = "Back", onClick = onBack)
        ActionButton(label = "Open Radar Adjustment", onClick = onOpenRadarAdjustment)
    }
}
