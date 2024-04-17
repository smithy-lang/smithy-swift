// Code generated by smithy-swift-codegen. DO NOT EDIT!

import ClientRuntime
import SmithyReadWrite
import SmithyTestUtil
@testable import WeatherSDK
import XCTest


class GetCityImageNoSuchResourceTest: HttpResponseTestBase {
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

            let getCityImageOutputError = try await wireResponseErrorClosure(GetCityImageOutputError.httpErrorBinding, wireResponseDocumentBinding())(httpResponse)

            if let actual = getCityImageOutputError as? NoSuchResource {

                let expected = NoSuchResource(
                    message: "Your custom message",
                    resourceType: "City"
                )
                XCTAssertEqual(actual.httpResponse.statusCode, HttpStatusCode(rawValue: 404))
                XCTAssertEqual(expected.properties.resourceType, actual.properties.resourceType)
                XCTAssertEqual(expected.properties.message, actual.properties.message)
            } else {
                XCTFail("The deserialized error type does not match expected type")
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
