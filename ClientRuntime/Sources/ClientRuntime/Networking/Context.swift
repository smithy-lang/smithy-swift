//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

public struct Context<Output: HttpResponseBinding, OutputError: HttpResponseBinding> {
    let encoder: RequestEncoder
    let decoder: ResponseDecoder
    let outputType: Output
    let operation: String
    let serviceName: String
    let request: SdkHttpRequest
    let outputError: OutputError
    
    public init(encoder: RequestEncoder,
                decoder: ResponseDecoder,
                outputType: Output,
                outputError: OutputError,
                operation: String,
                serviceName: String,
                request: SdkHttpRequest) {
        self.encoder = encoder
        self.decoder = decoder
        self.outputType = outputType
        self.outputError = outputError
        self.operation = operation
        self.serviceName = serviceName
        self.request = request
    }
}
