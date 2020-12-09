/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// This class is used to pass context from the service clients to the middleware of the sdk
/// in order to decorate and execute the request as well as handle serde.
public class Context {
    let encoder: RequestEncoder
    let decoder: ResponseDecoder
    let operation: String
    let serviceName: String
    let method: HttpMethodType
    let path: String
    let attributes: Attributes
    
    public init(encoder: RequestEncoder,
                decoder: ResponseDecoder,
                operation: String,
                method: HttpMethodType,
                path: String,
                serviceName: String,
                attributes: Attributes) {
        self.encoder = encoder
        self.decoder = decoder
        self.operation = operation
        self.method = method
        self.path = path
        self.serviceName = serviceName
        self.attributes = attributes
    }
}
