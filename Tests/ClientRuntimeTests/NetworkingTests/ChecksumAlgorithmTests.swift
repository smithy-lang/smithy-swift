//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import ClientRuntime
import XCTest

class ChecksumAlgorithmTests: XCTestCase {
    let chunk1 = Data("Hello, world!".utf8)
    let chunk2 = Data("Hello again, world!".utf8)
    
    func test_crc32_computeHash() throws {
        let hashResult = try ChecksumAlgorithm.crc32.computeHash(of: chunk1)
        XCTAssertEqual(hashResult.toHexString(), "ebe6c6e6")
        XCTAssertEqual(hashResult.toBase64String(), "6+bG5g==")
    }
    
    func test_crc32c_computeHash() throws {
        let hashResult = try ChecksumAlgorithm.crc32c.computeHash(of: chunk1)
        XCTAssertEqual(hashResult.toHexString(), "c8a106e5")
        XCTAssertEqual(hashResult.toBase64String(), "yKEG5Q==")
    }
    
    func test_sha1_computeHash() throws {
        let hashResult = try ChecksumAlgorithm.sha1.computeHash(of: chunk1)
        XCTAssertEqual(hashResult.toHexString(), "943a702d06f34599aee1f8da8ef9f7296031d699")
        XCTAssertEqual(hashResult.toBase64String(), "lDpwLQbzRZmu4fjajvn3KWAx1pk=")
    }
    
    func test_sha256_computeHash() throws {
        let hashResult = try ChecksumAlgorithm.sha256.computeHash(of: chunk1)
        XCTAssertEqual(hashResult.toHexString(), "315f5bdb76d078c43b8ac0064e4a0164612b1fce77c869345bfc94c75894edd3")
        XCTAssertEqual(hashResult.toBase64String(), "MV9b23bQeMQ7isAGTkoBZGErH853yGk0W/yUx1iU7dM=")
    }
    
    func test_md5_computeHash() throws {
        let hashResult = try ChecksumAlgorithm.md5.computeHash(of: chunk1)
        XCTAssertEqual(hashResult.toHexString(), "6cd3556deb0da54bca060b4c39479839")
        XCTAssertEqual(hashResult.toBase64String(), "bNNVbesNpUvKBgtMOUeYOQ==")
    }
    
    func test_crc32_chunkedComputeHash() throws {
        let hashResult1 = try ChecksumAlgorithm.crc32.computeHash(of: chunk1)
        guard case .integer(let uintHash) = hashResult1 else {
            XCTFail("Hash result was not integer")
            return
        }
        let hashResult2 = try ChecksumAlgorithm.crc32.computeHash(of: chunk2, previousHash: uintHash)
        XCTAssertEqual(hashResult2.toHexString(), "1fb9c01e")
        XCTAssertEqual(hashResult2.toBase64String(), "H7nAHg==")
    }
    
    func test_crc32c_chunkedComputeHash() throws {
        let hashResult1 = try ChecksumAlgorithm.crc32c.computeHash(of: chunk1)
        guard case .integer(let uintHash) = hashResult1 else {
            XCTFail("Hash result was not integer")
            return
        }
        let hashResult2 = try ChecksumAlgorithm.crc32c.computeHash(of: chunk2, previousHash: uintHash)
        XCTAssertEqual(hashResult2.toHexString(), "947eaa39")
        XCTAssertEqual(hashResult2.toBase64String(), "lH6qOQ==")
    }
}
