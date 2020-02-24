plugins {
    kotlin("jvm") version "1.3.61"
    `java-library`
}

allprojects {
    group = "software.amazon.smithy"
    version = "0.1.0"
}

repositories {
    mavenCentral()
    mavenLocal()
}

subprojects {
    val subproject = this

    if (subproject.name != "smithy-swift-codegen-test") {
        apply(plugin = "kotlin")

        dependencies {
            implementation(kotlin("stdlib-jdk8"))
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



