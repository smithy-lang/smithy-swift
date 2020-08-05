//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import Foundation

extension StringProtocol where Self.Index == String.Index {
    func escape(_ characterSet: [(character: String, escapedCharacter: String)]) -> String {
        var string = String(self)

        for set in characterSet {
            string = string.replacingOccurrences(of: set.character, with: set.escapedCharacter, options: .literal)
        }

        return string
    }
}

extension StringProtocol {
    func capitalizingFirstLetter() -> Self {
        guard !isEmpty else {
            return self
        }
        return Self(prefix(1).uppercased() + dropFirst())!
    }

    mutating func capitalizeFirstLetter() {
        self = capitalizingFirstLetter()
    }

    func lowercasingFirstLetter() -> Self {
        // avoid lowercasing single letters (I), or capitalized multiples (AThing ! to aThing, leave as AThing)
        guard count > 1, !(String(prefix(2)) == prefix(2).lowercased()) else {
            return self
        }
        return Self(prefix(1).lowercased() + dropFirst())!
    }

    mutating func lowercaseFirstLetter() {
        self = lowercasingFirstLetter()
    }
}

extension StringProtocol {
    func base64EncodedString() throws -> String {
        let utf8Encoded = self.data(using: .utf8)
        guard let base64String = utf8Encoded?.base64EncodedString() else {
            throw ClientError.serializationFailed("Failed to base64 encode a String")
        }
        return base64String
    }
}
