// Code generated by smithy-swift-codegen. DO NOT EDIT!

import Foundation
import class SmithyHTTPAPI.HttpResponse
import struct SmithyTimestamps.TimestampFormatter

extension GetCityAnnouncementsOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> GetCityAnnouncementsOutput {
        var value = GetCityAnnouncementsOutput()
        if let lastUpdatedHeaderValue = httpResponse.headers.value(for: "x-last-updated") {
            value.lastUpdated = SmithyTimestamps.TimestampFormatter(format: .httpDate).date(from: lastUpdatedHeaderValue)
        }
        return value
    }
}
