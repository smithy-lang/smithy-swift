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
    var order: [String] = []
    
    mutating func add(position: Position, ids: String...) {
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
    
    mutating func insert(relativeTo: String, position: Position, ids: String...) {
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

public struct OrderedGroup<TSubject, TContext, TError: Error> {
    //order of the keys
    var order = RelativeOrder()
    //id:name
    private var _items: [String: AnyMiddleware<TSubject, TContext, TError>] = [:]
    
    var orderedItems: [String: AnyMiddleware<TSubject, TContext, TError>] {
        var sorted = [String: AnyMiddleware<TSubject, TContext, TError>]()
        for key in order.order {
            sorted[key] = self._items[key]
        }
        return sorted
    }
    
    public init() {}
    
    mutating func add(middleware: AnyMiddleware<TSubject, TContext, TError>,
                      position: Position) {
        if !middleware.id.isEmpty {
            _items[middleware.id] = middleware
            order.add(position: position, ids: middleware.id)
        }
    }
    
    mutating func insert(middleware: AnyMiddleware<TSubject, TContext, TError>,
                         relativeTo: String,
                         position: Position) {
        _items[middleware.id] = middleware
        order.insert(relativeTo: relativeTo, position: position, ids: middleware.id)
    }
    
    func get(id: String)-> AnyMiddleware<TSubject, TContext, TError>? {
        return _items[id]
    }
    
}
