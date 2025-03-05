/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.utils

// taken from smithy-kotlin, which was originally taken from java sdk: https://github.com/awslabs/smithy-kotlin/blob/main/smithy-kotlin-codegen/src/main/kotlin/software/amazon/smithy/kotlin/codegen/utils/CaseUtils.kt
fun String.splitOnWordBoundaries(): List<String> {
    // adapted from Java v2 SDK CodegenNamingUtils.splitOnWordBoundaries
    var result = this

    // all non-alphanumeric characters: "acm-success"-> "acm success"
    result = result.replace(Regex("[^A-Za-z0-9+_]"), " ")

    // if there is an underscore, split on it: "acm_success" -> "acm", "_", "success"
    result = result.replace(Regex("_"), " _ ")

    // if a number has a standalone v in front of it, separate it out
    result =
        result
            .replace(Regex("([^a-z]{2,})v([0-9]+)"), "$1 v$2 ") // TESTv4 -> "TEST v4 "
            .replace(Regex("([^A-Z]{2,})V([0-9]+)"), "$1 V$2 ") // TestV4 -> "Test V4 "

    // add a space between camelCased words
    result = result.split(Regex("(?<=[a-z])(?=[A-Z]([a-zA-Z]|[0-9]))")).joinToString(separator = " ") // AcmSuccess -> // "Acm Success"

    // add a space after acronyms
    result = result.replace(Regex("([A-Z]+)([A-Z][a-z])"), "$1 $2") // "ACMSuccess" -> "ACM Success"

    // add space after a number in the middle of a word
    result = result.replace(Regex("([0-9])([a-zA-Z])"), "$1 $2") // "s3ec2" -> "s3 ec2"

    // remove extra spaces - multiple consecutive ones or those and the beginning/end of words
    result =
        result
            .replace(Regex("\\s+"), " ") // "Foo  Bar" -> "Foo Bar"
            .trim() // " Foo " -> "Foo"

    return result.split(" ")
}

// See https://awslabs.github.io/smithy/1.0/spec/aws/aws-core.html#using-sdk-service-id-for-client-naming
fun String.clientName(): String = toUpperCamelCase()

fun String.toLowerCamelCase(): String {
    val words = this.splitOnWordBoundaries()

    // make first part lowercase
    val firstWord = words.first().lowercase()

    // join
    return firstWord + words.drop(1).joinToString(separator = "")
}

fun String.toUpperCamelCase(): String {
    val words = this.splitOnWordBoundaries()

    // make first part uppercase
    val firstWord = words.first().replaceFirstChar { c -> c.uppercaseChar() }

    // join
    return firstWord + words.drop(1).joinToString(separator = "")
}
