/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

public class HttpClientConfiguration {
    public var protocolType: ProtocolType
    // initialize with default headers
    public var defaultHeaders: Headers
    // TODO: this file will change post AWS Service config design most likely.
    // add any other properties here you want to give the service operations
    // control over to be mapped to the Http Client

    public init(protocolType: ProtocolType = .https,
                defaultHeaders: Headers = Headers()) {
        self.protocolType = protocolType
        self.defaultHeaders = defaultHeaders
    }
}
