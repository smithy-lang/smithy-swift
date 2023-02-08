/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public protocol RequestEncoder {
    func encode<T>(_ value: T) throws -> Data where T: Encodable
}
