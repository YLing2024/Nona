import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 正式签名配置：读取 key.properties（本地生成，不入库）或环境变量。
// 缺失时回退 debug 签名（仅用于本地调试构建）。
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

fun String?.orEnv(name: String): String? = this?.takeIf { it.isNotBlank() } ?: System.getenv(name)

val releaseStoreFile = keystoreProperties.getProperty("storeFile")?.orEnv("NONA_KEYSTORE_FILE")
    ?: System.getenv("NONA_KEYSTORE_FILE")
val releaseStorePassword = keystoreProperties.getProperty("storePassword")?.orEnv("NONA_KEYSTORE_PASSWORD")
val releaseKeyAlias = keystoreProperties.getProperty("keyAlias")?.orEnv("NONA_KEYSTORE_ALIAS")
val releaseKeyPassword = keystoreProperties.getProperty("keyPassword")?.orEnv("NONA_KEYSTORE_KEY_PASSWORD")

android {
    namespace = "com.nona.chat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.nona.chat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseStoreFile != null && releaseStorePassword != null &&
            releaseKeyAlias != null && releaseKeyPassword != null
        ) {
            create("release") {
                storeFile = rootProject.file(releaseStoreFile)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            // 优先使用正式签名；未配置 keystore 时回退 debug 签名（本地调试）
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
