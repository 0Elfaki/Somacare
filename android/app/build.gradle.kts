import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Release signing ─────────────────────────────────────────────────────────
//
// Read from android/key.properties, which must stay out of version control:
//
//   storeFile=C:/keys/somacare-upload.jks
//   storePassword=…
//   keyAlias=upload
//   keyPassword=…
//
// Create the keystore once:
//   keytool -genkey -v -keystore somacare-upload.jks -keyalg RSA \
//           -keysize 2048 -validity 10000 -alias upload
//
// Without the file the release build falls back to the DEBUG key so that
// `flutter run --release` still works locally. A debug-signed bundle can never
// be uploaded to Google Play, so CI must supply key.properties.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasReleaseSigning) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

if (!hasReleaseSigning) {
    logger.lifecycle(
        "SomaCare: android/key.properties not found — release builds will be " +
            "signed with the debug key and CANNOT be uploaded to Google Play."
    )
}

android {
    namespace = "com.example.telemedicine101"
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
        // A `com.example.*` application id is rejected by the Play Console.
        // This is the app's permanent public identity — it cannot be changed
        // after the first upload, so it is set now rather than at ship time.
        // (The Kotlin `namespace` above may stay as-is; the two are allowed
        // to differ, and renaming it would move MainActivity.kt.)
        applicationId = "com.somacare.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            isMinifyEnabled = true
            isShrinkResources = true
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
