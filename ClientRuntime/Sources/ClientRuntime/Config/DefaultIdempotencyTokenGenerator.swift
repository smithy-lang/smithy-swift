//
//  File.swift
//  
//
//  Created by Adireddy, Santosh on 12/21/20.
//

import Foundation

class DefaultIdempotencyTokenGenerator : IdempotencyTokenGeneratorProtocol {
    func generateToken() -> String {
        return UUID().uuidString
    }
}
