// Code generated by smithy-swift-codegen. DO NOT EDIT!

import ClientRuntime
import SmithyTestUtil
@testable import WeatherSDK
import XCTest


class GetCityResponseTest: HttpResponseTestBase {
    /// Does something
    func testWriteGetCityResponseAssertions() async throws {
        guard let httpResponse = buildHttpResponse(
            code: 200,
            headers: nil,
            content: .data(Data("""
            {
                "name": "Seattle",
                "coordinates": {
                    "latitude": 12.34,
                    "longitude": -56.78
                },
                "city": {
                    "cityId": "123",
                    "name": "Seattle",
                    "number": "One",
                    "case": "Upper"
                }
            }
            """.utf8))
        ) else {
            XCTFail("Something is wrong with the created http response")
            return
        }

        let actual: GetCityOutput = try await GetCityOutput.httpOutput(from:)(httpResponse)

        let expected = GetCityOutput(
            city: WeatherClientTypes.CitySummary(
                case: "Upper",
                cityId: "123",
                name: "Seattle",
                number: "One"
            ),
            coordinates: WeatherClientTypes.CityCoordinates(
                latitude: 12.34,
                longitude: -56.78
            ),
            name: "Seattle"
        )

        XCTAssertEqual(expected.name, actual.name)
        XCTAssertEqual(expected.coordinates, actual.coordinates)
        XCTAssertEqual(expected.city, actual.city)

    }
}
