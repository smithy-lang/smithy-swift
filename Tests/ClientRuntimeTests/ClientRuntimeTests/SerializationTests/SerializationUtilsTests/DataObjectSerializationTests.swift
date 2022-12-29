/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest

class DataObjectSerializationTests: XCTestCase {
    
    struct StructWithDataObject: Codable {
        let data: Data
        
        init(data: Data) {
            self.data = data
        }
    }
    
    func testDataObjectIsEncodedToBase64String() {
        let validBase64EncodableStrings = [
            "ABC": "QUJD",
            "this is a 32 byte long string!!!": "dGhpcyBpcyBhIDMyIGJ5dGUgbG9uZyBzdHJpbmchISE=",
            "": "",
            "ユニコードとはか？": "44Om44OL44Kz44O844OJ44Go44Gv44GL77yf",
            "hello\tworld\n": "aGVsbG8Jd29ybGQK"
        ]
        
        for (validBase64EncodableString, base64EncodedValue) in validBase64EncodableStrings {
            guard let testDataObject = validBase64EncodableString.data(using: .utf8) else {
                XCTFail("Failed to create test data object for base64Encodable string")
                return
            }
            let structWithDataObject = StructWithDataObject(data: testDataObject)
            guard let encodedStructWithDataObject = try? JSONEncoder().encode(structWithDataObject) else {
                XCTFail("Failed to encode struct with valid base64 encodable data object")
                return
            }
            
            guard let structWithDataObjectJSON = String(data: encodedStructWithDataObject, encoding: .utf8) else {
                XCTFail("encoded StructWithDataObject is not a valid JSON string")
                return
            }
            
            let expectedStructWithDataObjectJSON = "{\"data\":\"\(base64EncodedValue)\"}"
            XCTAssertEqual(structWithDataObjectJSON, expectedStructWithDataObjectJSON)
        }
    }
    
    func testDecodingDataObjectFromBase64EncodedString() {
        let validBase64EncodableStrings = [
            "ABC": "QUJD",
            "this is a 32 byte long string!!!": "dGhpcyBpcyBhIDMyIGJ5dGUgbG9uZyBzdHJpbmchISE=",
            "": "",
            "ユニコードとはか？": "44Om44OL44Kz44O844OJ44Go44Gv44GL77yf",
            "hello\tworld\n": "aGVsbG8Jd29ybGQK"
        ]
        
        for (validBase64EncodableString, base64EncodedValue) in validBase64EncodableStrings {
            let structWithDataObjectJSON = "{\"data\":\"\(base64EncodedValue)\"}"
            guard let encodedStructWithDataObjectJSON = structWithDataObjectJSON.data(using: .utf8) else {
                XCTFail("failed to encode string encodedStructWithDataObjectJSON using utf8 encoding")
                return
            }
            
            guard let structWithDataObject = try? JSONDecoder().decode(StructWithDataObject.self, from: encodedStructWithDataObjectJSON) else {
                XCTFail("failed to decode struct with data object that is base64 encoded")
                return
            }
            
            guard let decodedDataObjectString = String(data: structWithDataObject.data, encoding: .utf8) else {
                XCTFail("invalid decoded data object. Failed to convert to utf8 string")
                return
            }
            
            XCTAssertEqual(decodedDataObjectString, validBase64EncodableString)
        }
    }
    
    func testDecodingInvalidBase64EncodedDataObject() {
        let invalidBase64EncodedStrings = [
            // - is not a valid base64 char
            "Zm9v-y==",
            // encoded length is not a multiple of 4
            "Zm9vY=",
            // invalid padding
            // TODO: this does not pass on Linux, it is unclear of this is in fact an invalid amount of padding.
            "Zm9vY==="
        ]
        
        for invalidBase64EncodedString in invalidBase64EncodedStrings {
            let structWithDataObjectJSON = "{\"data\":\"\(invalidBase64EncodedString)\"}"
            guard let encodedStructWithDataObjectJSON = structWithDataObjectJSON.data(using: .utf8) else {
                XCTFail("failed to encode string encodedStructWithDataObjectJSON using utf8 encoding")
                return
            }
            XCTAssertNil(try? JSONDecoder().decode(StructWithDataObject.self, from: encodedStructWithDataObjectJSON))
        }
    }
}
