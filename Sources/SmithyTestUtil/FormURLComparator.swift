//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

public enum FormURLComparator {

    public static func formURLData(_ dataA: Data, isEqualTo dataB: Data) -> Bool {
        guard let a = String(data: dataA, encoding: .utf8), 
              let b = String(data: dataB, encoding: .utf8) else { return false }
        return form(a) == form(b)
    }

    private static func form(_ string: String) -> Set<String.SubSequence> {
        return Set(string.split(separator: "&"))
    }
}
