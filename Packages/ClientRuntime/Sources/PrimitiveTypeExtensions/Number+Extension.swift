/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

public extension Float {
    func encoded() -> String {
        let signed = self.sign == .minus ? "-" : ""
        if self.isNaN {
            return "\(signed)NaN"
        } else if self.isInfinite {
            return "\(signed)Infinity"
        } else {
            return "\(self)"
        }
    }
}

public extension Double {
    func encoded() -> String {
        let signed = self.sign == .minus ? "-" : ""
        if self.isNaN {
            return "\(signed)NaN"
        } else if self.isInfinite {
            return "\(signed)Infinity"
        } else {
            return "\(self)"
        }
    }
}

