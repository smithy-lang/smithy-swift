//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// A mock to get errors to compile.  Remove before merge.

public class XMLDecoder {

    public init() {}

    public func decode<T: Decodable>(responseBody: Data) throws -> T {
        throw "boom"
    }

    public func decode<T: Decodable>(_ type: T.Type, from: Data) throws -> T {
        throw "boom"
    }
}

extension String: Error {
    var localizedDescription: String { self }
}
