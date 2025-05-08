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

// Comment out or remove this line to avoid early evaluation
// subprojects {
//     project.evaluationDependsOn(":app")
// }

// Disable problematic unit test tasks without afterEvaluate
subprojects {
    tasks.configureEach {
        if (name == "generateDebugUnitTestConfig" || name == "generateReleaseUnitTestConfig") {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}