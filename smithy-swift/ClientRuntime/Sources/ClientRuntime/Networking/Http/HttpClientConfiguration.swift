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

import Foundation

public class HttpClientConfiguration {
    public var protocolType: ProtocolType
    //initialize with default headers
    public var defaultHeaders: Headers

    public var protocolClasses: [AnyClass]?

    //add any other properties here you want to give the service operations control over to be mappted to the urlsessionconfig below

    public init(protocolType: ProtocolType = .https,
                defaultHeaders: Headers = Headers(),
                protocolClasses: [AnyClass]? = nil) {
        self.protocolType = protocolType
        self.defaultHeaders = defaultHeaders
        self.protocolClasses = protocolClasses
    }
}


