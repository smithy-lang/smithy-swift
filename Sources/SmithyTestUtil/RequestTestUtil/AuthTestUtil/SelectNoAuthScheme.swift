//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import class Smithy.Context
import struct SmithyHTTPAuthAPI.SelectedAuthScheme

public struct SelectNoAuthScheme: SelectAuthScheme {
    public static let noAuthScheme = SelectedAuthScheme(
        schemeID: "smithy.api#noAuth",
        identity: nil,
        signingProperties: nil,
        signer: nil
    )

    public init() {}

    public func select(attributes: Context) async throws -> SelectedAuthScheme? {
        return SelectNoAuthScheme.noAuthScheme
    }
}
