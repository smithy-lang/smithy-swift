//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyReadWrite) import class SmithyCBOR.Reader
import class SmithyHTTPAPI.HTTPResponse

public struct RpcV2CborError: BaseError {
    public let code: String
    public let message: String?
    public let requestID: String?
    @_spi(SmithyReadWrite) public var errorBodyReader: Reader { responseReader }

    public let httpResponse: HTTPResponse
    private let responseReader: Reader

    @_spi(SmithyReadWrite)
    public init(httpResponse: HTTPResponse, responseReader: Reader, noErrorWrapping: Bool, code: String? = nil) throws {
        let sanitizedCode = code.map { sanitizeErrorType($0) }
        switch responseReader.cborValue {
        case .map(let errorDetails):
            if case let .text(errorCode) = errorDetails["__type"] {
                self.code = sanitizedCode ?? sanitizeErrorType(errorCode)
            } else {
                self.code = sanitizedCode ?? "UnknownError"
            }

            if case let .text(errorMessage) = errorDetails["Message"] {
                self.message  = errorMessage
            } else {
                self.message = nil
            }
        default:
            self.code = sanitizedCode ?? "UnknownError"
            self.message = nil
        }

        self.httpResponse = httpResponse
        self.responseReader = responseReader
        self.requestID = nil
    }
}
