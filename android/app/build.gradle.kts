import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.hydrate"
    ndkVersion = "27.0.12077973"
    compileSdk = 35 // Sesuaikan dengan versi terbaru Flutter

    defaultConfig {
        applicationId = "com.hydrate.pdbl"
        minSdkVersion(23) // Diperbaiki: menggunakan fungsi minSdkVersion()
        targetSdkVersion(33) // Diperbaiki: menggunakan fungsi targetSdkVersion()
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            isMinifyEnabled = true  // ✅ WAJIB diaktifkan jika shrinkResources digunakan
            isShrinkResources = true // ✅ Bisa diaktifkan jika ingin menghapus resource tidak terpakai
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug")
        }
    }

}

flutter {
    source = "../.."
}