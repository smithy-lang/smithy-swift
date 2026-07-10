//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum Numerics {

    public static func int32(_ value: Int) throws -> Int32 {
        guard let int32value = Int32(exactly: value) else {
            throw SerializerError("value \(value) does not fit into Int32")
        }
        return int32value
    }

    public static func int(_ value: Int64) throws -> Int {
        guard let intValue = Int(exactly: value) else {
            throw SerializerError("value \(value) does not fit into Int")
        }
        return intValue
    }
}
