/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

/// This class is used to pass context from the service clients to the middleware of the sdk
/// in order to decorate and execute the request as well as handle serde.
public class Context<Output, OutputError> where Output: HttpResponseBinding,
                                                OutputError: HttpResponseBinding {
    let encoder: RequestEncoder
    let decoder: ResponseDecoder
    let outputType: Output.Type
    let operation: String
    let serviceName: String
    let outputError: OutputError.Type
    
    public init(encoder: RequestEncoder,
                decoder: ResponseDecoder,
                outputType: Output.Type,
                outputError: OutputError.Type,
                operation: String,
                serviceName: String) {
        self.encoder = encoder
        self.decoder = decoder
        self.outputType = outputType
        self.outputError = outputError
        self.operation = operation
        self.serviceName = serviceName
    }
}
