import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// key.properties parollarni saqlaydi va git'ga KIRMAYDI (android/.gitignore).
// Shuning uchun uni faqat shu kompyuterda bor deb hisoblab bo'lmaydi.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val keystoreProperties = Properties()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "uz.strotech"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    // key.properties bo'lmasa release signingConfig'ni UMUMAN yaratmaymiz.
    // Ilgari `keystoreProperties["keyAlias"] as String` shartsiz cast edi — fayl
    // yo'q bo'lsa null'ni String'ga cast qilib, Gradle KONFIGURATSIYA bosqichida
    // NPE bilan yiqilardi. Gradle esa `android { }` blokini HAR QANDAY task uchun
    // baholaydi, ya'ni `flutter run` va debug build ham ishlamay qolardi.
    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "strotech.uz"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Release kaliti bo'lsa — u bilan imzolaymiz. Bo'lmasa debug kalitiga
            // tushamiz: build yiqilmaydi (lokal test/CI ishlaydi), lekin bunday
            // artefaktni Play qabul qilmaydi — ya'ni jimgina "imzosiz reliz"
            // chiqib ketmaydi.
            signingConfig = if (hasReleaseKeystore) {
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
