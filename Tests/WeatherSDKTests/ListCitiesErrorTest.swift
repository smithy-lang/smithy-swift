// Code generated by smithy-swift-codegen. DO NOT EDIT!

import ClientRuntime
import SmithyHTTPAPI
import SmithyReadWrite
import SmithyTestUtil
@testable import WeatherSDK
import XCTest


class ListCitiesNoSuchResourceTest: HttpResponseTestBase {
    /// Does something
    func testWriteNoSuchResourceAssertions() async throws {
        do {
            guard let httpResponse = buildHttpResponse(
                code: 404,
                headers: nil,
                content: .data(Data("""
                {
                    "resourceType": "City",
                    "message": "Your custom message",
                    "errorType": "NoSuchResource"
                }
                """.utf8))
            ) else {
                XCTFail("Something is wrong with the created http response")
                return
            }

            let listCitiesOutputError = try await ListCitiesOutputError.httpError(from:)(httpResponse)

            if let actual = listCitiesOutputError as? NoSuchResource {

                let expected = NoSuchResource(
                    message: "Your custom message",
                    resourceType: "City"
                )
                XCTAssertEqual(actual.httpResponse.statusCode, HttpStatusCode(rawValue: 404))
                XCTAssertEqual(actual, expected)
            } else {
                XCTFail("The deserialized error type does not match expected type")
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
