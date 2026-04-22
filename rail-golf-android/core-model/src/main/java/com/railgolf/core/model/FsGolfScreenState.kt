package com.railgolf.core.model

data class FsGolfScreenState(
    val label: String,
    val radarStatus: RadarStatus = RadarStatus.Unknown,
)
