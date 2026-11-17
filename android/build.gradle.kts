allprojects {
    repositories {
        // Sandbox-only: local curl-mirrored repo FIRST (Java cannot reach
        // the network here). Project repositories ignore the settings'
        // dependencyResolutionManagement repos, so the local repo must be
        // declared here too. See ~/downloads/maven-mirror.py.
        // TODO on a normal machine: remove the maven { ... } line below.
        maven { url = uri("file:///home/hatch/maven-repo") }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
