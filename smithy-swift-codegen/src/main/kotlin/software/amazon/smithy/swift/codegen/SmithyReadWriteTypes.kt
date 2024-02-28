/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.model.buildSymbol

/**
 * Commonly used runtime types. Provides a single definition of a runtime symbol such that codegen isn't littered
 * with inline symbol creation which makes refactoring of the runtime more difficult and error prone.
 *
 * NOTE: Not all symbols need be added here but it doesn't hurt to define runtime symbols once.
 */
object SmithyReadWriteTypes {
    val WritingClosure = runtimeSymbol("WritingClosure")
    val ReadingClosure = runtimeSymbol("ReadingClosure")
    val DocumentWritingClosure = runtimeSymbol("DocumentWritingClosure")
}

private fun runtimeSymbol(name: String): Symbol = buildSymbol {
    this.name = name
    this.namespace = SwiftDependency.SMITHY_READ_WRITE.target
    dependency(SwiftDependency.SMITHY_XML)
}
