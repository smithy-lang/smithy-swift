description = "HTTP Core for Smithy services generated by smithy-kotlin"
extra["displayName"] = "Smithy :: Kotlin :: HTTP Core"
extra["moduleName"] = "software.aws.clientrt.http"

val ktorVersion: String by project

kotlin {

    sourceSets {
        commonMain {
            dependencies {
                implementation(project(":client-runtime:utils"))
                // for Pipeline abstraction which already supports suspend functions
                implementation("io.ktor:ktor-utils:$ktorVersion")
            }
        }

        jvmMain {
            dependencies {
                implementation("io.ktor:ktor-utils-jvm:$ktorVersion")
                implementation("io.ktor:ktor-io-jvm:$ktorVersion")
            }
        }
    }
}
