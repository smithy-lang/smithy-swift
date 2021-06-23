//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public var currentSwiftVersion: String {
    #if swift(>=5.6)
      #error("Cannot use a version of Swift greater than available")
    #elseif swift(>=5.5)
    return "5.5"
    #elseif swift(>=5.4)
    return "5.4"
    #elseif swift(>=5.3)
    return "5.3"
    #elseif swift(>=5.2)
    return "5.2"
    #elseif swift(>=5.1)
    return "5.1"
    #elseif swift(>=5.0)
    return "5.0"
    #else
    return "unknown"
    #endif
}

