package com.railgolf.feature.dashboard.model

import com.railgolf.core.model.FsGolfScreenState
import com.railgolf.core.model.ProxyStatus

data class DashboardState(
    val proxyStatus: ProxyStatus,
    val fsGolfScreenState: FsGolfScreenState,
)
