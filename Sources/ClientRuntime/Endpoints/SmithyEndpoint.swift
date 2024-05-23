//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/**
  A structure used by the service client to determine the endpoint.
  The SDK will automatically resolve endpoints per API client using an internal resolver.
 */
public struct SmithyEndpoint: Equatable {
    /**
    The endpoint object contains the host name,
    the transport protocol (e.g. "HTTPS") and the port to connect to when making requests to this endpoint.
     */
    public let endpoint: Endpoint

    /**
    Flag indicating that the hostname can be modified by the SDK client.
    If the hostname is mutable the SDK clients may modify any part of the hostname based
    on the requirements of the API (e.g. adding or removing content in the hostname). If the hostname
    is expected to be mutable and the client cannot modify the endpoint correctly, the operation
    will likely fail.
    */
    public let isHostnameImmutable: Bool
    /**
     The service name that should be used for signing requests to this endpoint.
     This overrides the default signing name used by an SDK client.
     */
    public let signingName: String?

    public init(endpoint: Endpoint,
                isHostnameImmutable: Bool = false,
                signingName: String? = nil) {
        self.endpoint = endpoint
        self.isHostnameImmutable = isHostnameImmutable
        self.signingName = signingName
    }
}
