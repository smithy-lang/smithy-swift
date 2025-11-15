//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct ModelError: Error {
    public let localizedDescription: String

    init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }
}
