// OWNER: AI-04 (placeholder created by AI-02's scaffold: no CMake yet)
//
// AI-04 adds externalNativeBuild (CMake 3.22.1, src/cmake/android.cmake), the two arm64 shims
// (armv8-a, armv8.2-a+fp16+dotprod) plus x86_64, c++_static, 16 KB page alignment, and the
// vw_exports.map version script. No armeabi-v7a (D-43(b)).

group = "com.vecvel.vwish.whisper"
version = "1.1.0"

buildscript {
    val kotlinVersion = "2.3.20"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.0.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "com.vecvel.vwish.whisper"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
