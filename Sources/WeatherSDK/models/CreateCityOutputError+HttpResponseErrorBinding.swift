// Code generated by smithy-swift-codegen. DO NOT EDIT!

import ClientRuntime
import SmithyHTTPAPI
import SmithyJSON
import SmithyReadWrite
import SmithyTestUtil
import class SmithyHTTPAPI.HttpResponse

enum CreateCityOutputError {

    static func httpError(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> Swift.Error {
        let data = try await httpResponse.data()
        let responseReader = try SmithyJSON.Reader.from(data: data)
        let baseError = try SmithyTestUtil.TestBaseError(httpResponse: httpResponse, responseReader: responseReader, noErrorWrapping: false)
        if let error = baseError.customError() { return error }
        switch baseError.code {
            default: return try ClientRuntime.UnknownHTTPServiceError.makeError(baseError: baseError)
        }
    }
}
