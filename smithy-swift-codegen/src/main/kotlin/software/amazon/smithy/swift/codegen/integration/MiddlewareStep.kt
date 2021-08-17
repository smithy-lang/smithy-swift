/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

enum class MiddlewareStep {
    INITIALIZESTEP {
        override fun stringValue(): String = "initializeStep"
    },
    BUILDSTEP {
        override fun stringValue(): String = "buildStep"
    },
    SERIALIZESTEP {
        override fun stringValue(): String = "serializeStep"
    },
    FINALIZESTEP {
        override fun stringValue(): String = "finalizeStep"
    },
    DESERIALIZESTEP {
        override fun stringValue(): String = "deserializeStep"
    };

    abstract fun stringValue(): String
}
