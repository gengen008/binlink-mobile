plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    // namespace must match the Kotlin package of MainActivity.kt (com.binlink.binlink_mobile)
    // applicationId differs per flavor — that's intentional and correct
    namespace = "com.binlink.binlink_mobile"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.binlink.eco"
        // API 23+ required for AES_GCM cipher in flutter_secure_storage
        // Android 6.0+ — covers 99%+ of active Ghana devices
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "app"
    productFlavors {
        create("household") {
            dimension = "app"
            applicationId = "com.binlink.eco"
            resValue("string", "app_name", "BinLink Eco")
        }
        create("collector") {
            dimension = "app"
            applicationId = "com.binlink.collector"
            resValue("string", "app_name", "BinLink Collector")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
