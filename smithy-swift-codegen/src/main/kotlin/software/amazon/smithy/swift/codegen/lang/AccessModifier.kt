/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

package software.amazon.smithy.swift.codegen.lang

/**
 * Swift access control modifiers.
 *
 * Note: This is an incomplete set - we can add more if we need.
 */
enum class AccessModifier {
    Public,
    PublicPrivateSet,
    Internal,
    Private,
    None;

    /**
     * Creates a string representation of the access control modifier.
     */
    fun rendered(): String = when (this) {
        Public -> "public"
        PublicPrivateSet -> "public private(set)"
        Internal -> "internal"
        Private -> "private"
        None -> ""
    }

    /**
     * Same as [rendered], but with a trailing space when not [None].
     */
    fun renderedRightPad(): String = when (this) {
        None -> ""
        else -> rendered().plus(" ")
    }
}
