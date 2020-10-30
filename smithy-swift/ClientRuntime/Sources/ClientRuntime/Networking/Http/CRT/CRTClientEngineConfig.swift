//
//  File.swift
//  
//
//  Created by Stone, Nicki on 10/30/20.
//

import Foundation

public struct CRTClientEngineConfig {
    let maxConnectionsPerEndpoint: Int
    
    let windowSize: Int
    
    let verifyPeer: Bool
    
    public init(maxConnectionsPerEndpoint: Int = 50,
         windowSize: Int = 16 * 1024 * 1024,
         verifyPeer: Bool = true) {
        self.maxConnectionsPerEndpoint = maxConnectionsPerEndpoint
        self.windowSize = windowSize
        self.verifyPeer = verifyPeer
        
    }
}
