buildscript {
    repositories {
        google()
        jcenter()
    }

    val kotlinVersion: String by project
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

plugins {
    kotlin("jvm") apply false
    id("org.jetbrains.dokka")
}

allprojects {
    repositories {
        mavenLocal()
        mavenCentral()
        jcenter()
    }
}

val ktlint by configurations.creating
val ktlintVersion: String by project

dependencies {
    ktlint("com.pinterest:ktlint:$ktlintVersion")
}

val lintPaths = listOf(
    "smithy-swift-codegen/src/**/*.kt"
)

tasks.register<JavaExec>("ktlint") {
    description = "Check Kotlin code style."
    group = "Verification"
    classpath = configurations.getByName("ktlint")
    main = "com.pinterest.ktlint.Main"
    args = lintPaths
}

tasks.register<JavaExec>("ktlintFormat") {
    description = "Auto fix Kotlin code style violations"
    group = "formatting"
    classpath = configurations.getByName("ktlint")
    main = "com.pinterest.ktlint.Main"
    args = listOf("-F") + lintPaths
}