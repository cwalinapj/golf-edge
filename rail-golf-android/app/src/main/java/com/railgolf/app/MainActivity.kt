package com.railgolf.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import com.railgolf.app.di.AppModule
import com.railgolf.app.navigation.AppNavGraph
import com.railgolf.core.ui.theme.RailGolfTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            RailGolfTheme {
                AppNavGraph(appModule = AppModule)
            }
        }
    }
}
