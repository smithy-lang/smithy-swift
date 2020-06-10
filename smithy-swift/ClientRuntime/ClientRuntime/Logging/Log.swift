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

import Foundation

public enum Log {
    static let level: Level = .verbose
    
    enum Level: Int {
        case error = 1
        case info = 2
        case verbose = 3
        
        func shouldLog(_ level: Level) -> Bool {
             return level.rawValue <= self.rawValue
         }
    }
    
    static func verbose(_ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
        if level.shouldLog(.verbose) {
            print(message())
        }
    }

    static func info(_ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
        if level.shouldLog(.info) {
            print(message())
        }
    }

    static func error(_ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
        // Check if we should log again here as we don't want to call the autoclosure if we can avoid it
        if level.shouldLog(.error) {
            print(message())
        }
    }
}
