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
