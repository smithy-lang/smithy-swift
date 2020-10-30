//
//  File.swift
//  
//
//  Created by Stone, Nicki on 10/29/20.
//

import Foundation

public protocol HttpClientEngine {
    func execute(request: AsyncRequest, completion: @escaping NetworkResult)
    func close()
}
