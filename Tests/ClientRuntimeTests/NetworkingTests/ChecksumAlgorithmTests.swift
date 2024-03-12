//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import ClientRuntime
import XCTest

class ChecksumAlgorithmTests: XCTestCase {
    let data = Data("Hello, world!".utf8)

    func test_crc32_computeHash() throws {
        let hashResult = try ChecksumAlgorithm.crc32.computeHash(of: data)
        XCTAssertEqual(hashResult.toHexString(), "ebe6c6e6")
    }

    func test_crc32c_computeHash() throws {
        let hashResult = try ChecksumAlgorithm.crc32c.computeHash(of: data)
        XCTAssertEqual(hashResult.toHexString(), "c8a106e5")
    }

    func test_sha1_computeHash() throws {
        let hashResult = try ChecksumAlgorithm.sha1.computeHash(of: data)
        XCTAssertEqual(hashResult.toHexString(), "943a702d06f34599aee1f8da8ef9f7296031d699")
    }

    func test_sha256_computeHash() throws {
        let hashResult = try ChecksumAlgorithm.sha256.computeHash(of: data)
        XCTAssertEqual(hashResult.toHexString(), "315f5bdb76d078c43b8ac0064e4a0164612b1fce77c869345bfc94c75894edd3")
    }

    func test_md5_computeHash() throws {
        let hashResult = try ChecksumAlgorithm.md5.computeHash(of: data)
        XCTAssertEqual(hashResult.toHexString(), "6cd3556deb0da54bca060b4c39479839")
    }
}
