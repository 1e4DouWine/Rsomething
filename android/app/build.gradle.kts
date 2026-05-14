import java.util.Properties
import org.gradle.api.GradleException
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle 插件需要在 Android 和 Kotlin 插件之后应用。
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun signingProperty(propertyName: String, environmentName: String): String? {
    val fileValue = keystoreProperties.getProperty(propertyName)
    if (!fileValue.isNullOrBlank()) return fileValue
    return System.getenv(environmentName)?.takeIf { it.isNotBlank() }
}

val releaseStoreFile = signingProperty("storeFile", "RELEASE_STORE_FILE")
val releaseStorePassword = signingProperty("storePassword", "RELEASE_STORE_PASSWORD")
val releaseKeyAlias = signingProperty("keyAlias", "RELEASE_KEY_ALIAS")
val releaseKeyPassword = signingProperty("keyPassword", "RELEASE_KEY_PASSWORD")
val hasReleaseSigning = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

android {
    namespace = "com.remembersomething.rs"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
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

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // 正式发布签名通过未提交的 android/key.properties 或 CI 环境变量注入。
            // 未配置时由发布打包任务明确失败，避免误用 debug key 分发。
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_21)
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

gradle.taskGraph.whenReady {
    val releasePackagingRequested = gradle.startParameter.taskNames.any { taskName ->
        val simpleName = taskName.substringAfterLast(':')
        simpleName.contains("Release") &&
            (simpleName.startsWith("assemble") ||
                simpleName.startsWith("bundle") ||
                simpleName.startsWith("package"))
    }
    if (releasePackagingRequested && !hasReleaseSigning) {
        throw GradleException(
            "Release signing is not configured. Create android/key.properties " +
                "from key.properties.example or provide RELEASE_STORE_FILE, " +
                "RELEASE_STORE_PASSWORD, RELEASE_KEY_ALIAS, and RELEASE_KEY_PASSWORD."
        )
    }
}
