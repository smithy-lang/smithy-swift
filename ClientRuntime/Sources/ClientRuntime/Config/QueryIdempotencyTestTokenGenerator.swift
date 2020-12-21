//
//  File.swift
//  
//
//  Created by Adireddy, Santosh on 12/21/20.
//

import Foundation

public class QueryIdempotencyTestTokenGenerator : IdempotencyTokenGeneratorProtocol {
    public init() {}
    public func generateToken() -> String {
        return "00000000-0000-4000-8000-000000000000"
    }
}
