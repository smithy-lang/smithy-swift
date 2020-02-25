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

    if (subproject.name != "smithy-java-codegen-test") {
        apply(plugin = "java-library")
        apply(plugin = "kotlin")
        dependencies {
            implementation(kotlin("stdlib-jdk8"))
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



