import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.simple_aac_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.simple_aac_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appName"] = "Simple AAC"
    }

    signingConfigs {
        create("release") {
            val keyAliasVal = keystoreProperties["keyAlias"] as String?
            val keyPasswordVal = keystoreProperties["keyPassword"] as String?
            val storePasswordVal = keystoreProperties["storePassword"] as String?
            val storeFilePath = keystoreProperties["storeFile"] as String?
            if (storeFilePath != null && keyAliasVal != null && storePasswordVal != null && keyPasswordVal != null) {
                keyAlias = keyAliasVal
                keyPassword = keyPasswordVal
                storePassword = storePasswordVal
                storeFile = rootProject.file(storeFilePath)
            }
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".dev"
            manifestPlaceholders["appName"] = "Simple AAC DEV"
        }
        release {
            val releaseSigning = signingConfigs.getByName("release")
            if (releaseSigning.storeFile == null || !releaseSigning.storeFile!!.exists()) {
                throw GradleException("Production release build requires a valid key.properties and keystore file. Release signing cannot fall back to debug.")
            }
            signingConfig = releaseSigning
        }
    }
}

flutter {
    source = "../.."
}
