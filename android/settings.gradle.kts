pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // Sandbox-only: local curl-mirrored repo FIRST (Java cannot reach
        // the network here). See ~/downloads/maven-mirror.py.
        maven { url = uri("file:///home/hatch/maven-repo") }
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    // Sandbox-only pin: KGP 2.1.0/2.3.0 crash on Gradle >= 8.0 with
    // NoSuchMethodError getIsolatedProjects() BuildOption$Value (their
    // "gradle76" accessor calls a Gradle internal that changed return type
    // in Gradle 8.0). KGP 2.0.21's accessor just returns false and works.
    // TODO on a normal machine: restore 2.1.0 (Flutter template default).
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
}

include(":app")
