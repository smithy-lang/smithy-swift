//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct SerdeBenchmarkMetadata: Codable {
    public let lang: String
    public let software: [[String]]
    public let os: String
    public let instance: String
    public let precision: String
}
