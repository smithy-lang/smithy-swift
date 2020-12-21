//
//  File.swift
//  
//
//  Created by Adireddy, Santosh on 12/21/20.
//

import Foundation

public protocol IdempotencyTokenGeneratorProtocol {
    func generateToken() -> String
}

extension IdempotencyTokenGeneratorProtocol {
    public func generateToken() -> String {
        return UUID().uuidString
    }
}
