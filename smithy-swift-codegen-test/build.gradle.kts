/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

extra["displayName"] = "Smithy :: Swift :: Codegen :: Test"
extra["moduleName"] = "software.amazon.smithy.swift.codegen.test"

plugins {
    id("software.amazon.smithy").version("0.5.2")
    kotlin("jvm")
}

val smithyVersion: String by project

dependencies {
    implementation(project(":smithy-swift-codegen"))
    implementation("software.amazon.smithy:smithy-aws-protocol-tests:$smithyVersion")
    implementation("software.amazon.smithy:smithy-protocol-test-traits:$smithyVersion")
    implementation("software.amazon.smithy:smithy-aws-traits:$smithyVersion")
    implementation(kotlin("stdlib-jdk8"))
}
repositories {
    mavenCentral()
}

task<Exec>("buildGeneratedSDK") {
    val pathToGeneratedSDK = "$buildDir/smithyprojections/smithy-swift-codegen-test/source/swift-codegen"
    workingDir(".")
    commandLine("which", "swift")
    isIgnoreExitValue=true
    dependsOn(tasks["build"])

    doLast {
        if(execResult?.exitValue == 0) {
            println("Found swift executable")
            exec {
                workingDir(pathToGeneratedSDK)
                commandLine("swift", "build")
            }
        } else {
            println("Could not find swift executable. Skip buildGeneratedSDK.")
        }
    }
}

tasks["jar"].enabled = false
tasks["build"].finalizedBy(getTasksByName("buildGeneratedSDK", true))

val compileKotlin: KotlinCompile by tasks

compileKotlin.kotlinOptions {
    jvmTarget = "1.8"
}

val compileTestKotlin: KotlinCompile by tasks

compileTestKotlin.kotlinOptions {
    jvmTarget = "1.8"
}
