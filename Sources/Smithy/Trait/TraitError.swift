//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Used to throw errors relating to trait-related anomalies.
public struct TraitError: Error {
    public let localizedDescription: String

    public init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}
