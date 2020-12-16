/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

extension JSONDecoder: ResponseDecoder {
    public func decode<T>(responseBody: Data) throws -> T where T: Decodable {
        return try decode(T.self, from: responseBody)
    }
}
