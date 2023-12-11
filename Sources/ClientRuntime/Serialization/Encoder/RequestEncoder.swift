/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

public protocol RequestEncoder {
    func encode<T: Encodable>(_ value: T) throws -> Data
}
