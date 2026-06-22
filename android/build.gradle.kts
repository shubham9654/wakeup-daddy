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
}
// Force every plugin module to compile against a modern SDK. Some plugins
// (e.g. `alarm`) still target compileSdk 34, which conflicts with transitive
// deps like flutter_fgbg that require 35+. Registered before the
// evaluationDependsOn(":app") below so projects aren't yet evaluated.
fun org.gradle.api.Project.forceCompileSdk() {
    extensions.findByName("android")?.let { ext ->
        (ext as com.android.build.gradle.BaseExtension).compileSdkVersion(36)
    }
}

subprojects {
    if (state.executed) {
        forceCompileSdk()
    } else {
        afterEvaluate { forceCompileSdk() }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
