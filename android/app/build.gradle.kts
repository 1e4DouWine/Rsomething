plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle 插件需要在 Android 和 Kotlin 插件之后应用。
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.remembersomething.rs"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        // 使用稳定且唯一的应用 ID，避免继续保留 Flutter 模板默认包名。
        applicationId = "com.remembersomething.rs"
        // 版本、SDK 等构建参数继续跟随 Flutter 配置，保持多端构建一致。
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // 本地未配置发布签名时沿用调试签名，正式分发应由 CI/发布环境注入 release 签名。
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
