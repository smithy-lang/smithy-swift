//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import ClientRuntime
import AwsCommonRuntimeKit

class HashFunctionTests: XCTestCase {

    func testCRC32() {
        guard let hashFunction = HashFunction.from(string: "crc32") else {
            XCTFail("CRC32 not found")
            return
        }

        // Create test data
        let testBytes: [UInt8] = [0xFF, 0xFE, 0xFD, 0xFC] // Bytes not valid in UTF-8
        let testData = Data(testBytes)

        let result = try? hashFunction.computeHash(of: testData)?.toUInt32()
        let expected = testData.computeCRC32()
        XCTAssertEqual(result, expected, "CRC32 hash does not match expected value")
    }

    func testCRC32C() {
        guard let hashFunction = HashFunction.from(string: "crc32c") else {
            XCTFail("CRC32C not found")
            return
        }

        // Create test data
        let testBytes: [UInt8] = [0xFF, 0xFE, 0xFD, 0xFC] // Bytes not valid in UTF-8
        let testData = Data(testBytes)

        let result = try? hashFunction.computeHash(of: testData)?.toUInt32()
        let expected = testData.computeCRC32C()
        XCTAssertEqual(result, expected, "CRC32C hash does not match expected value")
    }

    func testSHA1() {
        guard let hashFunction = HashFunction.from(string: "sha1") else {
            XCTFail("SHA1 not found")
            return
        }

        // Create test data
        let testBytes: [UInt8] = [0xFF, 0xFE, 0xFD, 0xFC] // Bytes not valid in UTF-8
        let testData = Data(testBytes)

        let result = try? hashFunction.computeHash(of: testData)
        let expected = try? testData.computeSHA1()
        XCTAssertEqual(result, expected, "SHA1 hash does not match expected value")
    }

    func testSHA256() {
        guard let hashFunction = HashFunction.from(string: "sha256") else {
            XCTFail("SHA256 not found")
            return
        }

        // Create test data
        let testBytes: [UInt8] = [0xFF, 0xFE, 0xFD, 0xFC] // Bytes not valid in UTF-8
        let testData = Data(testBytes)

        let result = try? hashFunction.computeHash(of: testData)
        let expected = try? testData.computeSHA256()
        XCTAssertEqual(result, expected, "SHA256 hash does not match expected value")
    }

    func testMD5() {
        guard let hashFunction = HashFunction.from(string: "md5") else {
            XCTFail("MD5 not found")
            return
        }

        // Create test data
        let testBytes: [UInt8] = [0xFF, 0xFE, 0xFD, 0xFC] // Bytes not valid in UTF-8
        let testData = Data(testBytes)

        let result = try? hashFunction.computeHash(of: testData)
        let expected = try? testData.computeMD5()
        XCTAssertEqual(result, expected, "MD5 hash does not match expected value")
    }

    func testInvalidHashFunction() {
        let invalidHashFunction = HashFunction.from(string: "invalid")
        XCTAssertNil(invalidHashFunction, "Invalid hash function should return nil")
    }

    func testDataConversionUInt32() {
        let originalValue: UInt32 = 1234567890
        let dataRepresentation = Data(fromUInt32: originalValue)
        let convertedValue = dataRepresentation.toUInt32()
        XCTAssertEqual(originalValue, convertedValue, "Conversion to and from UInt32 failed")
    }

    func testHashFunctionToHexString() {
        // Must be called to work on linux
        CommonRuntimeKit.initialize()

        let testData = Data("Hello, world!".utf8)

        // CRC32
        if let crc32Function = HashFunction.from(string: "crc32"),
           let crc32Result = try? crc32Function.computeHash(of: testData)?.toUInt32() {
            XCTAssertEqual(crc32Result.toHexString(), "ebe6c6e6", "CRC32 hexadecimal representation does not match expected value")
        } else {
            XCTFail("CRC32 hash function not found or computation failed")
        }

        // CRC32C
        if let crc32cFunction = HashFunction.from(string: "crc32c"),
           let crc32cResult = try? crc32cFunction.computeHash(of: testData)?.toUInt32() {
            XCTAssertEqual(crc32cResult.toHexString(), "c8a106e5", "CRC32C hexadecimal representation does not match expected value")
        } else {
            XCTFail("CRC32C hash function not found or computation failed")
        }

        // SHA1
        if let sha1Function = HashFunction.from(string: "sha1"),
           let sha1Result = try? sha1Function.computeHash(of: testData) {
            XCTAssertEqual(sha1Result.toHexString(), "943a702d06f34599aee1f8da8ef9f7296031d699", "SHA1 hexadecimal representation does not match expected value")
        } else {
            XCTFail("SHA1 hash function not found or computation failed")
        }

        // SHA256
        if let sha256Function = HashFunction.from(string: "sha256"),
           let sha256Result = try? sha256Function.computeHash(of: testData) {
            XCTAssertEqual(sha256Result.toHexString(), "315f5bdb76d078c43b8ac0064e4a0164612b1fce77c869345bfc94c75894edd3", "SHA256 hexadecimal representation does not match expected value")
        } else {
            XCTFail("SHA256 hash function not found or computation failed")
        }

        // MD5
        if let md5Function = HashFunction.from(string: "md5"),
           let md5Result = try? md5Function.computeHash(of: testData) {
            XCTAssertEqual(md5Result.toHexString(), "6cd3556deb0da54bca060b4c39479839", "MD5 hexadecimal representation does not match expected value")
        } else {
            XCTFail("MD5 hash function not found or computation failed")
        }
    }

}
