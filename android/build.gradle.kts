buildscript {
    val kotlin_version by extra("1.9.23") // You can update this to your desired Kotlin version
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // The Android Gradle Plugin version is managed by the Flutter Gradle Plugin.
        // If you need to override this, see: https://docs.flutter.dev/deployment/android#managing-the-android-gradle-plugin-version
        // classpath("com.android.tools.build:gradle:...")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:${property("kotlin_version")}")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
