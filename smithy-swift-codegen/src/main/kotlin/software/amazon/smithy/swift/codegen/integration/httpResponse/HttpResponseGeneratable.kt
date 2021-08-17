/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

interface HttpResponseGeneratable {
    fun render(ctx: ProtocolGenerator.GenerationContext, httpOperations: List<OperationShape>, httpBindingResolver: HttpBindingResolver)
}
