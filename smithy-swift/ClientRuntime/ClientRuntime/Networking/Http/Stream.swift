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



extension InputStream {
    public func readData(maxLength length: Int) throws -> Data {
        var buffer = [UInt8](repeating: 0, count: length)
        let result = self.read(&buffer, maxLength: buffer.count)
        if result < 0 {
            throw self.streamError ?? POSIXError(.EIO)
        } else {
            return Data(buffer.prefix(result))
        }
    }
}

extension OutputStream {
    public func write<DataType: DataProtocol>(_ data: DataType) throws -> Int {
        var buffer = Array(data)
        let result = self.write(&buffer, maxLength: buffer.count)
        if result < 0 {
            throw self.streamError ?? POSIXError(.EIO)
        } else {
            return result
        }
    }
}
