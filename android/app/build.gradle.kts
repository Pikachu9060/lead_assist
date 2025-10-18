plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.android.gms:play-services-safetynet:18.1.0")

    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.4.0")) // Use a stable version

    // Firebase dependencies - choose ONE of the auth implementations below:

    // Option 1: Use the BoM-managed version (recommended)
    implementation("com.google.firebase:firebase-auth")

    // Option 2: If you need the -ktx version specifically, use this:
    // implementation("com.google.firebase:firebase-auth-ktx")

    // Other Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-firestore") // If using Firestore

    // TODO: Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
}

android {
    namespace = "com.example.leadassist"
    compileSdk = 36 // Changed to 34 for better compatibility
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        // Remove the duplicate VERSION_11 lines
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        multiDexEnabled = true
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.leadassist"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = 34 // Use fixed version instead of flutter.targetSdkVersion
        versionCode = 1 // Use fixed version or flutter.versionCode
        versionName = "1.0.0" // Use fixed version or flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}