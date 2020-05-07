plugins {
    kotlin("jvm")
    id("org.jetbrains.dokka")
    jacoco
}

description = "Generates Swift code from Smithy models"
extra["displayName"] = "Smithy :: Swift :: Codegen"
extra["moduleName"] = "software.amazon.smithy.swift.codegen"

group = "software.amazon.smithy"
version = "0.1.0"

dependencies {
    implementation(kotlin("stdlib-jdk8"))
    api("software.amazon.smithy:smithy-codegen-core:0.9.9")
    implementation("software.amazon.smithy:smithy-protocol-test-traits:0.9.9")
    testImplementation("org.junit.jupiter:junit-jupiter:5.6.1")
    testImplementation("io.kotest:kotest-assertions-core-jvm:4.0.5")
}

tasks.test {
    useJUnitPlatform()
    testLogging {
        events("passed", "skipped", "failed")
        showStandardStreams = true
    }
}

// Reusable license copySpec
val licenseSpec = copySpec {
    from("${project.rootDir}/LICENSE")
    from("${project.rootDir}/NOTICE")
}

// Configure jars to include license related info
tasks.jar {
    metaInf.with(licenseSpec)
    inputs.property("moduleName", project.name)
    manifest {
        attributes["Automatic-Module-Name"] = project.name
    }
}

tasks.dokka {
    outputFormat = "html"
    outputDirectory = "$buildDir/javadoc"
}

// Always build documentation
tasks["build"].finalizedBy(tasks["dokka"])

// Configure jacoco (code coverage) to generate an HTML report
tasks.jacocoTestReport {
    reports {
        xml.isEnabled = false
        csv.isEnabled = false
        html.destination = file("$buildDir/reports/jacoco")
    }
}

// Always run the jacoco test report after testing.
tasks["test"].finalizedBy(tasks["jacocoTestReport"])