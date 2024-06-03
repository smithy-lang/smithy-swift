//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.ProcessInfo

public struct PlatformOperationSystemVersion {
    static public func operatingSystemVersion() -> String? {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
    }
}
