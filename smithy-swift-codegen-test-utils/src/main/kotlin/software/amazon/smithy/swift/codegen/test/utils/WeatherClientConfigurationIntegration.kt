/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.test.utils

import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration

class WeatherClientConfigurationIntegration : SwiftIntegration {

    override val protocolGenerators: List<ProtocolGenerator>
        get() {
            return listOf(FakeProtocolGenerator())
        }
}
