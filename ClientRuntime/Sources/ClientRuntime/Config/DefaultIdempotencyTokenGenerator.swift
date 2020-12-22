//
//  File.swift
//  
//
//  Created by Adireddy, Santosh on 12/21/20.
//

import Foundation

public class DefaultIdempotencyTokenGenerator: IdempotencyTokenGeneratorProtocol {
    
    public init() {}
    
    public func generateToken() -> String {
        return UUID().uuidString
    }
}
