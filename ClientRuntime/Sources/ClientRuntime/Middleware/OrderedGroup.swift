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

struct RelativeOrder {
    var order: [String]
    
    mutating func add(position: Position, ids: [String]) {
        if ids.count == 0 { return}
        var unDuplicatedList = ids
        for index in  0...(ids.count - 1) {
            let id = ids[index]
            if order.contains(id) {
                //if order already has the id, remove it from the list so it is not re-inserted
                unDuplicatedList.remove(at: index)
            }
        }
        
        switch position {
        case .after:
            order.append(contentsOf: unDuplicatedList)
        case .before:
            order.insert(contentsOf: unDuplicatedList, at: 0)
        }
    }
    
    mutating func insert(relativeTo: String, position: Position, ids: [String]) {
        if ids.count == 0 {return}
        let indexOfRelativeItem = order.firstIndex(of: relativeTo)
        if let indexOfRelativeItem = indexOfRelativeItem {
            switch position {
            
            case .before:
                order.insert(contentsOf: ids, at: indexOfRelativeItem - 1)
            case .after:
                order.insert(contentsOf: ids, at: indexOfRelativeItem)
            }
    
        }
    }
    
    func has(id: String) -> Bool {
       return order.contains(id)
    }
    
    mutating func clear() {
        order.removeAll()
    }
}

public struct OrderedGroup {
    //order of the keys
    let order: RelativeOrder
    //id:name
    var items: [String: Middleware] {
        get {
        var sorted = [String: Middleware]()
        for key in order.order {
            sorted[key] = self.items[key]
        }
        return sorted
        }
        set {
        
        }
    }
    
    mutating func add(middleware: Middleware, position: Position) {
        if !middleware.id.isEmpty {
            items[middleware.id] = middleware
        }
    }
    
    mutating func insert(middleware: Middleware, relativeTo: String, position: Position) {
        items[middleware.id] = middleware
    }
    
    func get(id: String)-> Middleware? {
        return items[id]
    }
    
}
