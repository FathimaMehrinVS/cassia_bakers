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
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
    if (android != null) {
        if (android.namespace == null) {
            android.namespace = "com." + project.name.replace("_", "").replace("-", "")
        }
    } else {
        if (!state.executed) {
            afterEvaluate {
                val ext = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
                if (ext != null && ext.namespace == null) {
                    ext.namespace = "com." + project.name.replace("_", "").replace("-", "")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
