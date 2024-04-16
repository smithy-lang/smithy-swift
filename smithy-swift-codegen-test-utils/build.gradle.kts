/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
description = "Generates Test Weather SDK Client code from Smithy models"
extra["displayName"] = "Smithy :: Swift :: Codegen :: Test :: Utils"
extra["moduleName"] = "software.amazon.smithy.swift.codegen.test.utils"

plugins {
    kotlin("jvm")
}

repositories {
    mavenLocal()
    mavenCentral()
}

dependencies {
    implementation(kotlin("stdlib-jdk8"))
    implementation(project(":smithy-swift-codegen"))
}
