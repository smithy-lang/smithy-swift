//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Returns the swift version of the compiler that is compiling this application.
public var swiftVersion: String {
    /**
     Unfortunately there isn't a way to grab the compiled swift programmatically and so we must resot to the compiler directives to produce a version string.
     We are checking for quite a few versions in the future, that may never exist, in order to future proof our current SDKs. Ideally, all current SDKs should compile
     on future Swift versions unless that Swift version introduces a breaking change.
     
     TODO add handling for Swift 8.x versions when Swift 6.0 is released.
     */
    return swift5Version()
    ?? swift6Version()
    ?? swift7Version()
    ?? "unknown"
}

private func swift5Version() -> String? {
    #if swift(>=6.0)
    return nil
    #elseif swift(>=5.9)
    return "5.9"
    #elseif swift(>=5.8)
    return "5.8"
    #elseif swift(>=5.7)
    return "5.7"
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
    return nil
    #endif
}

private func swift6Version() -> String? {
    #if swift(>=7.0)
    return nil
    #elseif swift(>=6.9)
    return "6.9"
    #elseif swift(>=6.8)
    return "6.8"
    #elseif swift(>=6.7)
    return "6.7"
    #elseif swift(>=6.6)
    return "6.6"
    #elseif swift(>=6.5)
    return "6.5"
    #elseif swift(>=6.4)
    return "6.4"
    #elseif swift(>=6.3)
    return "6.3"
    #elseif swift(>=6.2)
    return "6.2"
    #elseif swift(>=6.1)
    return "6.1"
    #elseif swift(>=6.0)
    return "6.0"
    #else
    return nil
    #endif
}

private func swift7Version() -> String? {
    #if swift(>=8.0)
    return nil
    #elseif swift(>=7.9)
    return "7.9"
    #elseif swift(>=7.8)
    return "7.8"
    #elseif swift(>=7.7)
    return "7.7"
    #elseif swift(>=7.6)
    return "7.6"
    #elseif swift(>=7.5)
    return "7.5"
    #elseif swift(>=7.4)
    return "7.4"
    #elseif swift(>=7.3)
    return "7.3"
    #elseif swift(>=7.2)
    return "7.2"
    #elseif swift(>=7.1)
    return "7.1"
    #elseif swift(>=7.0)
    return "7.0"
    #else
    return nil
    #endif
}
