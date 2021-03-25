/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public struct Endpoint: Hashable {
    public let path: String
    public let queryItems: [URLQueryItem]?
    public let protocolType: ProtocolType?
    public let host: String
    public let port: Int16
    
    public init(host: String,
                path: String = "/",
                port: Int16 = 443,
                queryItems: [URLQueryItem]? = nil,
                protocolType: ProtocolType? = .https) {
        self.host = host
        self.path = path
        self.port = port
        self.queryItems = queryItems
        self.protocolType = protocolType
    }
}

public extension Endpoint {
    // We still have to keep 'url' as an optional, since we're
    // dealing with dynamic components that could be invalid.
    var url: URL? {
        var components = URLComponents()
        components.scheme = protocolType?.rawValue
        components.host = host
        components.path = path
        components.queryItems = queryItems
        // for local development
        components.port = Int(port)

        return components.url
    }
    
    var urlString: String {
        /*
         TODO: Before removing the references to XMLCoder in our code base, the body of this function
         was the following two lines:
         
             let queryItemString = queryItems != nil && queryItems!.isEmpty ? "?\(queryItems!.xmlString ?? "")" : ""
             return host + path + queryItemString
         
         To the best of our knowlege `queryItems!.xmlString` was always returning nil.
         https://github.com/awslabs/smithy-swift/pull/79/files
         
         For example, this would always return nil:
             let myQueryItem = URLQueryItem(name: "meow", value: "woof")
             let myQueryItems = [myQueryItem]
             print("my string is: \(myQueryItems.xmlString)")   //This returns nil!
         
         We believe this returns nil (and therefore renders an empty string) because of this code:
         https://github.com/awslabs/smithy-swift/blob/5ff9cac8cde13374785eaa20f751c33ae1ce9bec/Packages/ClientRuntime/Sources/Serialization/XML/XMLContainers/XMLArrayBasedContainer.swift#L18
         
         To unblock development, we will simply return a question mark, until we figure out what we need
         to encode for the return value.
         */
        let queryItemString = queryItems != nil && queryItems!.isEmpty ? "?" : ""
        return host + path + queryItemString
    }
}
