//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node

extension Node {
    
    /// Returns the node, rendered into a Swift literal for use in generated code.
    ///
    /// The node is rendered with some interstitial whitespace but single-line.
    var rendered: String {
        switch self {
        case .object(let object):
            guard !object.isEmpty else { return "[:]" }
            return "[" + object.map { "\($0.key.literal): \($0.value.rendered)" }.joined(separator: ",") + "]"
        case .list(let list):
            return "[" + list.map { $0.rendered }.joined(separator: ", ") + "]"
        case .string(let string):
            return string.literal
        case .number(let number):
            return "\(number)"
        case .boolean(let bool):
            return "\(bool)"
        case .null:
            return "nil"
        }
    }
}
