import com.android.build.api.variant.LibraryAndroidComponentsExtension

plugins {
    id("com.android.library") apply false
}

val mobileNdkVersion = providers.gradleProperty("deviceGuide.ndkVersion")
val mobileCompileSdk = providers.gradleProperty("deviceGuide.compileSdk").map(String::toInt)
val mobileCmakeVersion = providers.gradleProperty("deviceGuide.cmakeVersion")

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    plugins.withId("com.android.library") {
        // Compile Flutter plugins with the SDKs installed for our Android app.
        extensions.getByType<LibraryAndroidComponentsExtension>().finalizeDsl { android ->
            android.compileSdk = maxOf(android.compileSdk ?: 0, mobileCompileSdk.get())
            android.ndkVersion = mobileNdkVersion.get()
            val cmake = android.externalNativeBuild.cmake
            if (cmake.path != null && cmake.version == null) cmake.version = mobileCmakeVersion.get()
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
