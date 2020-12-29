// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

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

public struct OrderedGroup<Input, Output, Context: MiddlewareContext> {
    //order of the keys
    var order = RelativeOrder()
    //key here is name of the middleware aka the id property of the middleware
    private var _items: [String: AnyMiddleware<Input, Output, Context>] = [:]
    
    var orderedItems: [String: AnyMiddleware<Input, Output, Context>] {
        var sorted = [String: AnyMiddleware<Input, Output, Context>]()
        for key in order.order {
            sorted[key] = self._items[key]
        }
        return sorted
    }
    
    public init() {}
    
    mutating func add(middleware: AnyMiddleware<Input, Output, Context>,
                      position: Position) {
        if !middleware.id.isEmpty {
            _items[middleware.id] = middleware
            order.add(position: position, ids: middleware.id)
        }
    }
    
    mutating func insert(middleware: AnyMiddleware<Input, Output, Context>,
                         relativeTo: String,
                         position: Position) {
        _items[middleware.id] = middleware
        order.insert(relativeTo: relativeTo, position: position, ids: middleware.id)
    }
    
    func get(id: String)-> AnyMiddleware<Input, Output, Context>? {
        return _items[id]
    }
}
