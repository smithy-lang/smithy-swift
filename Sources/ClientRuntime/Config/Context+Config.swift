//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import class Smithy.ContextBuilder
import struct Smithy.AttributeKey

public extension Context {

    var clientConfig: DefaultClientConfiguration? {
        get { get(key: clientConfigKey) }
        set { set(key: clientConfigKey, value: newValue) }
    }
}

public extension ContextBuilder {

    func withClientConfig(value: DefaultClientConfiguration?) -> Self {
        attributes.set(key: clientConfigKey, value: value)
        return self
    }
}

private let clientConfigKey: AttributeKey<DefaultClientConfiguration> =
    AttributeKey<DefaultClientConfiguration>(name: "SmithySwiftClientConfig")
