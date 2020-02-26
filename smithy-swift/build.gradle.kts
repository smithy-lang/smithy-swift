plugins {
    kotlin("jvm") version "1.3.61"
    `java-library`
}

allprojects {
    group = "software.amazon.smithy"
    version = "0.1.0"
}

// The root project doesn't produce a JAR.
tasks["jar"].enabled = false

repositories {
    mavenCentral()
    mavenLocal()
}

subprojects {
    val subproject = this

    if (subproject.name != "smithy-swift-codegen-test") {
        apply(plugin = "java-library")
        apply(plugin = "kotlin")

        dependencies {
            implementation(kotlin("stdlib-jdk8"))
        }

        // Reusable license copySpec
        val licenseSpec = copySpec {
            from("${project.rootDir}/LICENSE")
            from("${project.rootDir}/NOTICE")
        }

        repositories {
            mavenCentral()
            mavenLocal()
        }

        tasks {
            compileKotlin {
                kotlinOptions.jvmTarget = "1.8"
            }
            compileTestKotlin {
                kotlinOptions.jvmTarget = "1.8"
            }
        }
    }
}



