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

open class Configuration {
    public var encoder: RequestEncoder?
    public var decoder: ResponseDecoder?
    public let httpClientEngine: HttpClientEngine?
    public let httpClientConfiguration: HttpClientConfiguration
    
    public init(encoder: RequestEncoder? = nil,
                decoder: ResponseDecoder? = nil,
                httpClientEngine: HttpClientEngine? = nil,
                httpClientConfiguration: HttpClientConfiguration = HttpClientConfiguration()) {
        self.encoder = encoder
        self.decoder = decoder
        self.httpClientEngine = httpClientEngine
        self.httpClientConfiguration = httpClientConfiguration
    }
}
