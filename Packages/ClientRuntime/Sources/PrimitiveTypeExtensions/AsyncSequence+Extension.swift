//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AsyncSequence {
    public func asyncCompactMap<T>(
        _ transform: (Element) -> [T]?
    ) async rethrows -> [T] {
        var values = [T]()

        for try await element in self {
            if let element = transform(element) {
                values.append(contentsOf: element)
            }
        }

        return values
    }
}
