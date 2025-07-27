/* android/app/build.gradle.kts */

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")          // modernare alias än "kotlin-android"
    // Flutter‑plugin MÅSTE appliceras sist enligt dokumentationen.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Detta ersätter gamla package="…" i AndroidManifest.xml
    namespace = "com.example.wf3_app"

    compileSdk  = flutter.compileSdkVersion      // värden injiceras av Flutter‑plugin
    ndkVersion = "27.0.12077973"

    defaultConfig {
        // Blir även ditt Play Store‑id. Håll det i synk med namespace (så slipper du förvirring).
        applicationId = "com.example.wf3_app"

        minSdk       = flutter.minSdkVersion
        targetSdk    = flutter.targetSdkVersion
        versionCode  = flutter.versionCode
        versionName  = flutter.versionName
    }

    compileOptions {
        // AGP 8 kräver Java 11 som lägst; tar vi 11 blir livet lugnt.
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // Matcha JVM‑bytecode med ovanstående.
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            // Byt till din riktiga sign‑konfiguration längre fram.
            signingConfig = signingConfigs.getByName("debug")

            // Uncomment om du vill krympa & obfuskera prod‑builds.
            // minifyEnabled = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

flutter {
    // Pekar ut rotmappen där pubspec.yaml ligger.
    source = "../.."
}
