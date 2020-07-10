/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import software.amazon.smithy.swift.gradle.tasks.BuildGeneratedSDK

extra["displayName"] = "Smithy :: Swift :: Codegen :: Test"
extra["moduleName"] = "software.amazon.smithy.swift.codegen.test"

plugins {
    id("software.amazon.smithy").version("0.5.0")
    kotlin("jvm")
}
dependencies {
    implementation(project(":smithy-swift-codegen"))
    implementation("software.amazon.smithy:smithy-protocol-test-traits:1.0.0")
    implementation("software.amazon.smithy:smithy-aws-traits:1.0.0")
    implementation(kotlin("stdlib-jdk8"))
}
repositories {
    mavenCentral()
}

tasks.register<BuildGeneratedSDK>("buildGeneratedSDK") {
    pathToGeneratedSDK = "$buildDir/smithyprojections/smithy-swift-codegen-test/source/swift-codegen"
    dependsOn(tasks["build"])
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