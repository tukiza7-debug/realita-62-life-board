plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.serialization")
}

android {
    namespace = "id.realita62.lifeboard"
    compileSdk = 34

    defaultConfig {
        applicationId = "id.realita62.lifeboard"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables.useSupportLibrary = true
    }

    signingConfigs {
        create("release") {
            // Signing credentials injected via environment in CI (see .github/workflows/build-apk.yml).
            // For local builds, set REALITA_KEYSTORE_FILE / REALITA_KEYSTORE_PASSWORD / REALITA_KEY_ALIAS / REALITA_KEY_PASSWORD.
            // Only configure the release signing config if ALL FOUR env vars are present AND non-empty.
            val keystoreFile = System.getenv("REALITA_KEYSTORE_FILE")?.takeIf { it.isNotEmpty() }
            val storePass = System.getenv("REALITA_KEYSTORE_PASSWORD")?.takeIf { it.isNotEmpty() }
            val keyAlias = System.getenv("REALITA_KEY_ALIAS")?.takeIf { it.isNotEmpty() }
            val keyPass = System.getenv("REALITA_KEY_PASSWORD")?.takeIf { it.isNotEmpty() }
            if (keystoreFile != null && storePass != null && keyAlias != null && keyPass != null) {
                storeFile = file(keystoreFile)
                storePassword = storePass
                this.keyAlias = keyAlias
                keyPassword = keyPass
            }
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        release {
            // Minify is disabled for the v1.0.0 release to avoid R8 ProGuard
            // rule issues with kotlinx.serialization. Re-enabling is tracked
            // as a follow-up — see docs/AUDIT.md §7.
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Use the release keystore only if all four signing env vars are
            // present AND non-empty. Otherwise fall back to debug signing so
            // the build still produces an installable APK (CI without a
            // configured keystore secret still ships a debug-signed APK).
            val allSigningEnvPresent = listOf(
                System.getenv("REALITA_KEYSTORE_FILE"),
                System.getenv("REALITA_KEYSTORE_PASSWORD"),
                System.getenv("REALITA_KEY_ALIAS"),
                System.getenv("REALITA_KEY_PASSWORD")
            ).all { !it.isNullOrEmpty() }
            signingConfig = if (allSigningEnvPresent) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs = freeCompilerArgs + listOf("-Xjvm-default=all")
    }
    buildFeatures {
        compose = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.14"
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "META-INF/LICENSE*"
            excludes += "META-INF/NOTICE*"
        }
    }
    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            isReturnDefaultValues = true
        }
    }
    lint {
        abortOnError = false
        checkReleaseBuilds = false
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2024.06.00")
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.activity:activity-compose:1.9.1")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.4")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.4")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.4")

    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.animation:animation")
    implementation("androidx.compose.foundation:foundation")

    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")

    implementation("androidx.datastore:datastore-preferences:1.1.1")
    implementation("androidx.navigation:navigation-compose:2.7.7")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.8.1")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
