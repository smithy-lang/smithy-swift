description = "Test utilities for generated Smithy services"
extra["displayName"] = "Smithy :: Kotlin :: Test"
extra["moduleName"] = "software.aws.clientrt.smithy.test"

val kotlinVersion: String by project
kotlin {
    sourceSets {
        commonMain {
            dependencies {
                api(project(":client-runtime:protocol:http"))

                // FIXME - we likely want to replicate the runBlocking and not depend on this or else we would
                // have to publish this which was intended to be internal
                implementation(project(":client-runtime:testing"))

                implementation("org.jetbrains.kotlin:kotlin-test-common:$kotlinVersion")
                // implementation("org.jetbrains.kotlin:kotlin-test-annotations-common:$kotlinVersion")
            }
        }

        jvmMain {
            dependencies {
                implementation("org.jetbrains.kotlin:kotlin-test:$kotlinVersion")
            }
        }
    }
}
