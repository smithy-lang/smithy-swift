/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

package software.amazon.smithy.swift.codegen

import java.net.URL
import java.util.logging.Logger
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.Shape

open class TestsBase {

    protected val LOGGER: Logger = Logger.getLogger(TestsBase::class.java.name)

    protected fun createModelFromSmithy(smithyTestResourceName: String): Model {
        return Model.assembler()
            .addImport(getSmithyResource(smithyTestResourceName = smithyTestResourceName))
            .discoverModels()
            .assemble()
            .unwrap()
    }

    protected fun createSymbolProvider(): SymbolProvider? {
        return SymbolProvider { shape: Shape ->
            Symbol.builder()
                .name(shape.id.name)
                .namespace(shape.id.namespace, "/")
                .definitionFile(shape.id.name + ".txt")
                .build()
        }
    }

    private fun getSmithyResource(smithyTestResourceName: String): URL? {
        return TestsBase::class.java.classLoader.getResource("software.amazon.smithy.swift.codegen/$smithyTestResourceName")
    }

    protected fun createModelFromShapes(vararg shapes: Shape): Model {
        return Model.assembler()
                    .addShapes(*shapes)
                    .assemble()
                    .unwrap()
    }
}
