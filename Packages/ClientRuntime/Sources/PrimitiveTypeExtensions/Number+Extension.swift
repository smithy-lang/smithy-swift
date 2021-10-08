/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

public extension Float {
    func encoded() -> String {
        if self.isNaN {
            return "NaN"
        } else if self.isInfinite {
            let signed = self < 0 ? "-" : ""
            return "\(signed)Infinity"
        } else {
            return "\(self)"
        }
    }
}

public extension Double {
    func encoded() -> String {
        if self.isNaN {
            return "NaN"
        } else if self.isInfinite {
            let signed = self < 0 ? "-" : ""
            return "\(signed)Infinity"
        } else {
            return "\(self)"
        }
    }
}
