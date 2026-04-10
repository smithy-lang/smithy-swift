//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(Linux) && swift(>=6.0)
import FoundationEssentials
#else
import Foundation
#endif

@_spi(SmithyReadWrite)
public protocol WireDataProviding: AnyObject {

    func data() async throws -> Data
}
