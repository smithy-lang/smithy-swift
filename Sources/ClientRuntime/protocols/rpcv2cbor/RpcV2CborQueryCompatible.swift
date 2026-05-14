//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyReadWrite) import class SmithyCBOR.Reader
import class SmithyHTTPAPI.HTTPResponse

@_spi(SmithyReadWrite)
public enum RpcV2CborQueryCompatibleUtils {

    // This function returns a standard RpcV2Cbor base error
    // without the passed error details.
    //
    // QueryCompatibleUtils with error parsing are implemented
    // in AWS SDK for Swift.
    public static func makeQueryCompatibleError(
        httpResponse: HTTPResponse,
        responseReader: SmithyCBOR.Reader,
        noErrorWrapping: Bool,
        errorDetails: String?
    ) throws -> RpcV2CborError {
        return try RpcV2CborError(
            httpResponse: httpResponse,
            responseReader: responseReader,
            noErrorWrapping: noErrorWrapping
        )
    }
}
