//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum AwsCommonRuntimeKit.EndpointProperty
import struct Foundation.URLComponents
import enum Smithy.ClientError
import struct SmithyHTTPAPI.Endpoint
import enum SmithyHTTPAPI.EndpointPropertyValue
import struct SmithyHTTPAPI.Headers

extension Endpoint {

    public init(urlString: String,
                headers: Headers = Headers(),
                endpointProperties: [String: EndpointProperty]) throws {
        guard let url = URLComponents(string: urlString)?.url else {
            throw ClientError.unknownError("invalid url \(urlString)")
        }

        let properties = endpointProperties.mapValues(EndpointPropertyValue.init)
        try self.init(url: url, headers: headers, properties: properties)
    }
}

extension EndpointPropertyValue {

    init(_ endpointProperty: EndpointProperty) {
        switch endpointProperty {
        case .bool(let value):
            self = .bool(value)
        case .string(let value):
            self = .string(value)
        case .array(let values):
            self = .array(values.map(EndpointPropertyValue.init))
        case .dictionary(let dict):
            self = .dictionary(dict.mapValues(EndpointPropertyValue.init))
        }
    }
}
