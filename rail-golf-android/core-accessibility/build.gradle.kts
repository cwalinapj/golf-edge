plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.railgolf.core.accessibility"
    compileSdk = 35

    defaultConfig {
        minSdk = 28
    }
}

dependencies {
    implementation(project(":core-model"))
    implementation(project(":core-common"))

    implementation("androidx.core:core-ktx:1.13.1")
}
