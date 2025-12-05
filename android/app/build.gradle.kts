import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}



plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
//    id("com.google.gms.google-services")
}

android {
    namespace = "com.happy.happy_wedz"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.happy.happy_wedz"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 8
        versionName = "1.0.8"
    }
//    signingConfigs {
//        release {
//            keyAlias keystoreProperties['keyAlias']
//            keyPassword keystoreProperties['keyPassword']
//            storeFile file(keystoreProperties['storeFile'])
//            storePassword keystoreProperties['storePassword']
//        }
//    }
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false     // Disable code shrinking
            isShrinkResources = false   // Disable resource shrinking
        }
    }



//    signingConfigs {
//        create("release") {
//            keyAlias = project.findProperty("MY_KEY_ALIAS") as String
//            keyPassword = project.findProperty("MY_KEY_PASSWORD") as String
//            storeFile = file("my-key.jks")
//            storePassword = project.findProperty("MY_KEYSTORE_PASSWORD") as String
//        }
//    }
//    dependencies {
//        // Import the Firebase BoM
////        implementation(platform("com.google.firebase:firebase-bom:32.2.2"))
////
////
////        // TODO: Add the dependencies for Firebase products you want to use
////        // When using the BoM, don't specify versions in Firebase dependencies
////        implementation("com.google.firebase:firebase-analytics")
//
//
//        // Add the dependencies for any other desired Firebase products
//        // https://firebase.google.com/docs/android/setup#available-libraries
//    }



    dependencies {
        implementation(platform("com.google.firebase:firebase-bom:34.3.0"))
        implementation("com.google.firebase:firebase-auth-ktx:21.1.0")
        implementation("com.google.android.gms:play-services-auth:20.7.0")
        implementation("com.facebook.android:facebook-android-sdk:latest.release")
        implementation("com.google.firebase:firebase-analytics")
    }
//
//    buildTypes {
//        release {
//            signingConfig signingConfigs.release
//                    shrinkResources true
//            minifyEnabled true
//            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
//        }
//    }

//    buildTypes {
//        release {
//            // TODO: Add your own signing config for the release build.
//            // Signing with the debug keys for now, so `flutter run --release` works.
//            signingConfig = signingConfigs.getByName("debug")
//        }
//    }
}

flutter {
    source = "../.."
}

