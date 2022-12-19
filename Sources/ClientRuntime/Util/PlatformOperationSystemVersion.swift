//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(watchOS) || os(macOS) || os(tvOS)
import Foundation.NSProcessInfo

public struct PlatformOperationSystemVersion {
    static public func operatingSystemVersion() -> String? {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
    }
}
#else
// TODO: Implement for Linux & Windows
public struct PlatformOperationSystemVersion {
    static public func operatingSystemVersion() -> String? {
        return nil
    }
}
#endif
