import java.util.Properties // <<<--- IMPORT ADDED HERE

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // Using the more specific Kotlin plugin ID for .kts
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read version code and name from local.properties (Kotlin DSL version)
val localProperties = Properties() // Now can use Properties() directly due to import
val localPropertiesFile = rootProject.file("local.properties") // Use double quotes for strings in Kotlin
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { input -> // Kotlin way to read file
        localProperties.load(input)
    }
}

// Read keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { input ->
        keystoreProperties.load(input)
    }
}

// Get values from localProperties, providing defaults and ensuring correct types
val flutterVersionCode: Int = localProperties.getProperty("flutter.versionCode")?.toIntOrNull() ?: 1
val flutterVersionName: String = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    // <<< YOUR ACTUAL NAMESPACE. Ensure this is correct.
    // It's often the same as applicationId.
    // If your actual Kotlin/Java files are in com.example.safemama, this should be com.example.safemama
    // or you need to refactor your package structure.
    namespace = "com.safemama.app" // <<<--- CRITICAL: ENSURE THIS MATCHES YOUR ACTUAL PACKAGE STRUCTURE AND INTENDED ID
    compileSdk = 36  // Updated from 35 to 36

    // Set the NDK version required by your plugins
    ndkVersion = "27.0.12077973" // Make sure this NDK version is appropriate for your setup

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17  // UPDATED
        targetCompatibility = JavaVersion.VERSION_17  // UPDATED
    }

    kotlinOptions {
        jvmTarget = "17"  // UPDATED to match Java 17
    }

    signingConfigs {
        create("release") {
            // Only configure release signing if key.properties exists and has all required fields
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            val storePass = keystoreProperties.getProperty("storePassword")
            val keyAliasValue = keystoreProperties.getProperty("keyAlias")
            val keyPass = keystoreProperties.getProperty("keyPassword")
            
            if (storeFilePath != null && storePass != null && keyAliasValue != null && keyPass != null) {
                storeFile = file(storeFilePath)
                storePassword = storePass
                keyAlias = keyAliasValue
                keyPassword = keyPass
            }
        }
    }

    defaultConfig {
        // <<< CRITICAL: ENSURE THIS IS YOUR UNIQUE APPLICATION ID
        // This MUST match what you've set in Google Cloud Console for the Android OAuth client
        // and the scheme used in your AndroidManifest.xml and Flutter code for deep linking.
        applicationId = "com.safemama.app" // <<<--- CRITICAL: ENSURE THIS IS YOUR ACTUAL PACKAGE NAME

        minSdkVersion(23) // Your existing minSdkVersion
        targetSdkVersion(flutter.targetSdkVersion)
        versionCode = 12
        versionName = "1.0.1"
    }

    buildTypes {
        release {
            // Only use release signing if key.properties is properly configured
            // Otherwise, fall back to debug signing for development builds
            val hasReleaseConfig = keystoreProperties.getProperty("storeFile") != null &&
                                   keystoreProperties.getProperty("storePassword") != null &&
                                   keystoreProperties.getProperty("keyAlias") != null &&
                                   keystoreProperties.getProperty("keyPassword") != null
            
            if (hasReleaseConfig) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Use debug signing if release keystore is not configured
                // This allows building release APKs for testing without a production keystore
                println("WARNING: key.properties not found or incomplete. Using debug signing for release build.")
                println("To create a production build, set up key.properties with your keystore details.")
                signingConfig = signingConfigs.getByName("debug")
            }
            
            // Standard release build settings
            isShrinkResources = false
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Added for ML Kit models (this syntax is fine for .kts)
    aaptOptions {
        noCompress.add("tflite")
    }
}

// This section tells the Android build where to find the Flutter project code
flutter {
    source = "../.."
}

// Default Flutter dependencies block (this syntax is fine for .kts)
dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")  // ADDED
    implementation(kotlin("stdlib-jdk8")) // Standard Kotlin library
    // Google Play Billing Library for in-app subscriptions
    implementation("com.android.billingclient:billing:6.2.1")
    // Add other Android-specific dependencies here if needed
}
