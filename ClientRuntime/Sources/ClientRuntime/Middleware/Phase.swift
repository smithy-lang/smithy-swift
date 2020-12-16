 // Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 // SPDX-License-Identifier: Apache-2.0.

public struct Phase<TContext, TSubject, TError: Error> {
    let name: String
    var orderedMiddleware: OrderedGroup<TContext, TSubject, TError>
    
    public init(name: String) {
        self.name = name
        self.orderedMiddleware = OrderedGroup<TContext, TSubject, TError>()
    }
}

