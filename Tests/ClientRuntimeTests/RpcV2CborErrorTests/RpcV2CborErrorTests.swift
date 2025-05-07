//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SmithyReadWrite) import struct ClientRuntime.RpcV2CborError
import class SmithyHTTPAPI.HTTPResponse
@_spi(SmithyReadWrite) import class SmithyCBOR.Reader

final class RpcV2CborErrorTests: XCTestCase {
    let cborCode = "abc-def"
    let passedCode = "ghi-jkl"

    func test_init_usesCodeInCborMap() throws {
        let reader = Reader(nodeInfo: "", cborValue: .map(["__type": .text(cborCode)]))
        let httpResponse = HTTPResponse(body: .data(Data()), statusCode: .ok)
        let subject = try RpcV2CborError(httpResponse: httpResponse, responseReader: reader, noErrorWrapping: false)
        XCTAssertEqual(subject.code, cborCode)
    }

    func test_init_usesUnknownErrorCodeWhenCborMapIsEmpty() throws {
        let reader = Reader(nodeInfo: "", cborValue: .map([:]))
        let httpResponse = HTTPResponse(body: .data(Data()), statusCode: .ok)
        let subject = try RpcV2CborError(httpResponse: httpResponse, responseReader: reader, noErrorWrapping: false)
        XCTAssertEqual(subject.code, "UnknownError")
    }


    func test_init_usesUnknownErrorCodeWhenDataIsNotCborMap() throws {
        let reader = Reader(nodeInfo: "", cborValue: .array([]))
        let httpResponse = HTTPResponse(body: .data(Data()), statusCode: .ok)
        let subject = try RpcV2CborError(httpResponse: httpResponse, responseReader: reader, noErrorWrapping: false)
        XCTAssertEqual(subject.code, "UnknownError")
    }

    func test_init_overridesCodeWithPassedCodeWhenNonNil() throws {
        let reader = Reader(nodeInfo: "", cborValue: .map(["__type": .text(cborCode)]))
        let httpResponse = HTTPResponse(body: .data(Data()), statusCode: .ok)
        let subject = try RpcV2CborError(httpResponse: httpResponse, responseReader: reader, noErrorWrapping: false, code: passedCode)
        XCTAssertEqual(subject.code, passedCode)
    }
}
