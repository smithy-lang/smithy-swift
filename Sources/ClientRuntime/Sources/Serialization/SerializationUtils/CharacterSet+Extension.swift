//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation.NSCharacterSet

extension CharacterSet {
    public static var singleUrlQueryAllowed: CharacterSet {
        var cSet = CharacterSet.urlQueryAllowed
        cSet.remove(charactersIn: ":/?#[]@!$&'()*+,;=%")
        return cSet
    }
}
