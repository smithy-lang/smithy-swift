/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.formurl

fun String.indexAdvancedBy1(indexVariableName: String): String {
    return "$this.\\($indexVariableName.advanced(by: 1))"
}
