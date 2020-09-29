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

public final class Box<T> where T: Codable {
    public var value: T

    init(value: T) {
        self.value = value
    }
}

extension Box: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer()
        let value = try values.decode(T.self)
        self.init(value: value)
    }
}


