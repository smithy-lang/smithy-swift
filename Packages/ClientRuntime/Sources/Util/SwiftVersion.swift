//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public var swiftVersion: String {
    #if swift(>=5.7)
      #error("Cannot use a version of Swift greater than available. Please create a Github issue for us to add support for the version of Swift you want to use.")
    #elseif swift(>=5.6)
    return "5.6"
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
      #error("Cannot use a version of Swift less than 5.0")
    #endif
}
