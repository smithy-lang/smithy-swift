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

public struct AttributeKey<ValueType>: Hashable {
    let name: String
    
    public init(name: String) {
        self.name = name
    }
    
    func toString() -> String {
        return "ExecutionAttributeKey: \(name)"
    }
}

public struct Attributes {
    var attributes: [Int: Any] = [Int: Any]()
    
    public init() {}
    
    public func get<T: Any>(key: AttributeKey<T>) -> T? {
        return attributes[key.hashValue] as? T
    }
    
    public func contains<T>(key: AttributeKey<T>) -> Bool {
        return attributes[key.hashValue] != nil
    }
    
    public mutating func set<T: Any>(key: AttributeKey<T>, value: T) {
        attributes[key.hashValue] = value
    }
    
    public mutating func remove<T>(key: AttributeKey<T>) {
        attributes.removeValue(forKey: key.hashValue)
    }
}
