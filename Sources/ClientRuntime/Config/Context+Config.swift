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
        get { get(key: clientConfigKey)?.clientConfig }
        set { set(key: clientConfigKey, value: ClientConfigurationWrapper(clientConfig: newValue)) }
    }
}

public extension ContextBuilder {

    func withClientConfig(value: DefaultClientConfiguration?) -> Self {
        let wrapped = ClientConfigurationWrapper(clientConfig: value)
        attributes.set(key: clientConfigKey, value: wrapped)
        return self
    }
}

private let clientConfigKey = AttributeKey<ClientConfigurationWrapper>(name: "SmithySwiftClientConfigWrapper")

/// A wrapper used to allow a client configuration object to be placed in Context, since client config is not Sendable.
///
/// Placing the client config into Context is safe because the client config is not modified after being placed into Context.
/// Client config is unwrapped, then may be used to create a service client and make calls as part of performing an operation.
///
/// This type is public so that it may be accessed in other runtime modules.  It is protected as SPI because it is a cross-module
/// implementation detail that does not affect customers.
///
/// `@unchecked Sendable` is used to make the wrapper Sendable even though it is technically not, due to the non-Sendable
/// client config stored within.
@_spi(ClientConfigWrapper)
public final class ClientConfigurationWrapper: @unchecked Sendable {
    public let clientConfig: DefaultClientConfiguration

    init?(clientConfig: DefaultClientConfiguration?) {
        guard let clientConfig else { return nil }
        self.clientConfig = clientConfig
    }
}
