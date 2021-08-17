/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.formurl

import software.amazon.smithy.model.shapes.Shape

interface FormURLEncodeCustomizable {
    fun alwaysUsesFlattenedCollections(): Boolean
    fun customNameTraitGenerator(memberShape: Shape, defaultName: String): String
}
