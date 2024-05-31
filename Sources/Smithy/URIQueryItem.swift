//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct URIQueryItem: Hashable {
    public var name: String
    public var value: String?

    public init(name: String, value: String?) {
        self.name = name
        self.value = value
    }
}
