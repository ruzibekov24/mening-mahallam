import java.util.Properties
import java.io.FileInputStream

// Reliz imzosi sozlamalari `android/key.properties` faylidan
// o'qiladi. Fayl versiya nazoratiga TUSHMAYDI (.gitignore), chunki
// ichida kalit paroli bor.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.mahallam"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications shuni talab qiladi (push
        // bildirishnomalarni old planda ko'rsatish uchun kerak).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "uz.meningmahallam.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // ffmpeg_kit_flutter_new (video -> GIF avatar konvertatsiyasi)
        // API 24+ talab qiladi — Flutter'ning standart minSdk'idan
        // yuqori bo'lishi mumkin, shuning uchun aniq belgilangan.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storeType = keystoreProperties["storeType"] as String
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Haqiqiy reliz kaliti bilan imzolanadi.
            //
            // Ilgari bu yerda DEBUG kaliti turardi. Debug kaliti har
            // bir kompyuterda boshqacha va Play Store uni qabul
            // qilmaydi — ya'ni ilova tarqatilgandan keyin kalitni
            // almashtirish kerak bo'lardi, bu esa ilova o'rnatgan
            // HAR BIR foydalanuvchini uni o'chirib qayta o'rnatishga
            // majbur qilardi.
            //
            // `key.properties` bo'lmasa (masalan boshqa kompyuterda)
            // build imzosiz qoladi va Gradle bu haqda ogohlantiradi —
            // jimgina debug kalitiga qaytib ketmaydi.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
