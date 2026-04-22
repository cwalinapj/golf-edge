plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
}

android {
    namespace = "com.railgolf.feature.fsgolfcontrol"
    compileSdk = 35

    defaultConfig { minSdk = 28 }
    buildFeatures { compose = true }
}

dependencies {
    implementation(project(":core-accessibility"))
    implementation(project(":core-model"))
    implementation(project(":core-ui"))
    implementation(project(":core-common"))

    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.material3)
}
