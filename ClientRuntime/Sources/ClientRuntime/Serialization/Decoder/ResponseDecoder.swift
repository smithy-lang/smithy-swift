/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public protocol ResponseDecoder {
    func decode<T: Decodable>(responseBody: Data) throws -> T
}
