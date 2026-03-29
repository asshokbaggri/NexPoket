import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

// 🔐 Load keystore
val keystoreProperties = Properties()
val keystoreFile = rootProject.file("key.properties")

val hasKeystore = keystoreFile.exists()

if (hasKeystore) {
    keystoreProperties.load(FileInputStream(keystoreFile))
}

android {
    namespace = "com.nexpoket.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.nexpoket.app"
        minSdk = 21   // 🔥 FIXED (flutter.minSdkVersion हटाया)
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    // 🔥 IMPORTANT FIX (ADD THIS)
    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        if (hasKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            isMinifyEnabled = false
            isShrinkResources = false

            // 🔥 ADD THIS (IMPORTANT)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
