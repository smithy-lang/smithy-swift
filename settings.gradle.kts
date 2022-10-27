/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

pluginManagement {
    repositories {
        mavenCentral()
        maven("https://plugins.gradle.org/m2/")
        google()
        gradlePluginPortal()
    }

    // configure default plugin versions
    plugins {
        val kotlinVersion: String by settings
        val dokkaVersion: String by settings
        val kotlinxBenchmarkVersion: String by settings
        val smithyGradleVersion: String by settings
        id("org.jetbrains.dokka") version dokkaVersion
        id("org.jetbrains.kotlin.jvm") version kotlinVersion
        id("org.jetbrains.kotlinx.benchmark") version kotlinxBenchmarkVersion
        id("software.amazon.smithy") version smithyGradleVersion
    }
}

rootProject.name = "smithy-swift"

include("smithy-swift-codegen")
include("smithy-swift-codegen-test")
