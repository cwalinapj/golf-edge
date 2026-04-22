pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "rail-golf-android"

include(
    ":app",
    ":feature-dashboard",
    ":feature-proxy",
    ":feature-fsgolf-control",
    ":core-accessibility",
    ":core-pi-api",
    ":core-model",
    ":core-ui",
    ":core-common",
)
