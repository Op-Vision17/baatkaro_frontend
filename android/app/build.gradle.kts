
plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")

  
}

android {
    namespace = "com.example.baatkaro"
    compileSdk = flutter.compileSdkVersion
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.baatkaro"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // For smaller APKs use: flutter build apk --release --split-per-abi
        // (Do not set ndk.abiFilters here — it conflicts with --split-per-abi.)
    }

 buildTypes {
    release {
        // Enables code shrinking, obfuscation, and optimization
        isMinifyEnabled = true
        // Enables resource shrinking (removes unused drawables/layouts)
        isShrinkResources = true
        
        signingConfig = signingConfigs.getByName("debug")
        
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
    packagingOptions {
        resources {
            // Agora: exclude optional extensions to reduce size (~2–3 MB+)
            excludes += "lib/arm64-v8a/libagora_ai_denoise_extension.so"
            excludes += "lib/arm64-v8a/libagora_spatial_audio_extension.so"
            excludes += "lib/arm64-v8a/libagora_segmentation_extension.so"
            excludes += "lib/arm64-v8a/libagora_video_process_extension.so"
            excludes += "lib/armeabi-v7a/libagora_ai_denoise_extension.so"
            excludes += "lib/armeabi-v7a/libagora_spatial_audio_extension.so"
            excludes += "lib/armeabi-v7a/libagora_segmentation_extension.so"
            excludes += "lib/armeabi-v7a/libagora_video_process_extension.so"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
}
