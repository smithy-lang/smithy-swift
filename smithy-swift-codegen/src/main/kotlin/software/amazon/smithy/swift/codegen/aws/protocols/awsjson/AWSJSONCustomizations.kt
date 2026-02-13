/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.aws.protocols.awsjson

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.integration.DefaultHTTPProtocolCustomizations
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes

open class AWSJSONCustomizations : DefaultHTTPProtocolCustomizations() {
    override val baseErrorSymbol: Symbol = ClientRuntimeTypes.Http.UnknownHttpServiceError

    override val defaultTimestampFormat = TimestampFormatTrait.Format.EPOCH_SECONDS
}
