/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.middleware

enum class MiddlewarePosition {
    BEFORE {
        override fun stringValue(): String = ".before"
    },
    AFTER {
        override fun stringValue(): String = ".after"
    };

    abstract fun stringValue(): String
}
