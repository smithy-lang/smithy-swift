// Code generated by smithy-swift-codegen. DO NOT EDIT!

import Foundation
import class SmithyHTTPAPI.HttpResponse
import class SmithyJSON.Reader

extension GetCurrentTimeOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> GetCurrentTimeOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyJSON.Reader.from(data: data)
        let reader = responseReader
        var value = GetCurrentTimeOutput()
        value.time = try reader["time"].readTimestampIfPresent(format: .epochSeconds)
        return value
    }
}
