//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct NodeInfo {

    public enum Location {
        case element
        case attribute
    }

    public struct Namespace: Equatable {
        let prefix: String
        let uri: String

        public init(prefix: String, uri: String) {
            self.prefix = prefix
            self.uri = uri
        }
    }

    public let name: String
    public let location: Location
    public let namespace: Namespace?

    public init(_ name: String, location: Location = .element, namespace: Namespace? = nil) {
        self.name = name
        self.location = location
        self.namespace = namespace
    }
}
