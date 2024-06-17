/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

plugins {
    id("software.amazon.smithy").version("0.5.3")
}

description = "Smithy protocol test suite"

val smithyVersion: String by project

buildscript {
    val smithyVersion: String by project
    dependencies {
        classpath("software.amazon.smithy:smithy-aws-traits:$smithyVersion")
    }
}

dependencies {
    implementation(project(":smithy-swift-codegen"))
    implementation(project(":smithy-swift-codegen-test-utils"))
}

repositories {
    mavenLocal()
    mavenCentral()
}

val outputDir: String
    get() = project.file("${project.buildDir}/smithyprojections/${project.name}/weather/swift-codegen").absolutePath

val sourcesDir: String
    get(){
        return rootProject.file("Sources").absolutePath
    }

val testsDir: String
    get(){
        return rootProject.file("Tests").absolutePath
    }

task("stageSdks") {
    group = "codegen"
    description = "relocate generated SDK(s) from build directory to Sources and Tests directories"
    doLast {
        logger.warn("copying ${outputDir}/WeatherSDK source to ${sourcesDir}")
        delete("$sourcesDir/WeatherSDK")
        delete("$sourcesDir/WeatherSDKTests")
        copy {
            from("$outputDir/Sources/WeatherSDK")
            into("$sourcesDir/WeatherSDK")
            exclude("Package.swift")
        }
        copy {
            from("$outputDir/Tests/WeatherSDKTests")
            into("$testsDir/WeatherSDKTests")
            exclude("Package.swift")
        }
    }
}

tasks.named("build") {
    finalizedBy("stageSdks")
}

