package com.railgolf.app.navigation

import androidx.compose.runtime.Composable
import com.railgolf.app.di.AppModule
import com.railgolf.feature.dashboard.ui.DashboardRoute

@Composable
fun AppNavGraph(appModule: AppModule) {
    DashboardRoute()
}
