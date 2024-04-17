// Code generated by smithy-swift-codegen. DO NOT EDIT!

import ClientRuntime
import SmithyJSON
import SmithyReadWrite
import SmithyTestUtil

enum CreateCityOutputError {

    static var httpErrorBinding: SmithyReadWrite.WireResponseErrorBinding<ClientRuntime.HttpResponse, SmithyJSON.Reader> {
        { httpResponse, responseDocumentClosure in
            let responseReader = try await responseDocumentClosure(httpResponse)
            let baseError = try SmithyTestUtil.JSONError(httpResponse: httpResponse, responseReader: responseReader, noErrorWrapping: false)
            switch baseError.code {
                default: return try ClientRuntime.UnknownHTTPServiceError.makeError(httpResponse: httpResponse, message: baseError.message, requestID: baseError.requestID, typeName: baseError.code)
            }
        }
    }
}
