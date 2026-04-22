package com.railgolf.core.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val RailGolfColors = darkColorScheme(
    primary = RailGreen,
    background = RailDark,
)

@Composable
fun RailGolfTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = RailGolfColors,
        typography = RailGolfTypography,
        content = content,
    )
}
