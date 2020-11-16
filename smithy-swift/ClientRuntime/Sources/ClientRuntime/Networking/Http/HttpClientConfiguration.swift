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

public class HttpClientConfiguration {
    public var protocolType: ProtocolType
    //initialize with default headers
    public var defaultHeaders: Headers
    //TODO: this file will change post AWS Service config design most likely.
    //add any other properties here you want to give the service operations control over to be mapped to the Http Client

    public init(protocolType: ProtocolType = .https,
                defaultHeaders: Headers = Headers()) {
        self.protocolType = protocolType
        self.defaultHeaders = defaultHeaders
    }
}
