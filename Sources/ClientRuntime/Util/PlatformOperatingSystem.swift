//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum PlatformOperatingSystem: String {
    case windows
    case linux
    case iOS
    case macOS
    case watchOS
    case tvOS
    case unknown
    case visionOS
}

public var currentOS: PlatformOperatingSystem {
    #if os(Linux)
    return .linux
    #elseif os(macOS)
    return .macOS
    #elseif os(iOS)
    return .iOS
    #elseif os(watchOS)
    return .watchOS
    #elseif os(Windows)
    return .windows
    #elseif os(tvOS)
    return .tvOS
    #elseif os(visionOS)
    return .visionOS
    #else
     #error("Cannot use a an operating system we do not support")
    #endif
}
