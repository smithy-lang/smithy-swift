// Code generated by smithy-swift-codegen. DO NOT EDIT!

import ClientRuntime
import SmithyHTTPAPI
import SmithyJSON
import SmithyReadWrite

extension GetCityOutput {

    static func httpOutput(from httpResponse: SmithyHTTPAPI.HttpResponse) async throws -> GetCityOutput {
        let data = try await httpResponse.data()
        let responseReader = try SmithyJSON.Reader.from(data: data)
        let reader = responseReader
        var value = GetCityOutput()
        value.city = try reader["city"].readIfPresent(with: WeatherClientTypes.CitySummary.read(from:))
        value.coordinates = try reader["coordinates"].readIfPresent(with: WeatherClientTypes.CityCoordinates.read(from:))
        value.name = try reader["name"].readIfPresent()
        return value
    }
}
