allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Har bir submodul (jumladan `:app`) ham shu ko'chirilgan build papkasiga
// yozsin. Busiz `:app` o'zining standart `android/app/build/` papkasiga
// yozardi, Flutter esa artefaktni `<loyiha>/build/app/...` dan qidiradi —
// natijada Gradle muvaffaqiyatli tugasa ham `flutter build apk/appbundle`
// "Gradle build failed to produce an .apk file" deb yiqilardi.
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        val project = this
        if (project.hasProperty("android")) {
            project.extensions.configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(36)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
