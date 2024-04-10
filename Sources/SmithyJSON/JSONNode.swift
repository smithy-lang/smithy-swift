//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.NSNumber

enum JSONNode: Equatable {
    case bool(Bool)
    case number(NSNumber)
    case string(String)
    case null
    case array
    case object
}

enum JSONError: Error {
    case unknownJSONContent
}
