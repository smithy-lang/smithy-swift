//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import struct ClientRuntime.UnknownHTTPServiceError
@_spi(SchemaBasedSerde)
import RestJSON1ResponseTestSDK

/// Tests the RestJSON1 client protocol's deserialization of error response bodies.
final class HTTPClientProtocolErrorTests: XCTestCase, RestJSON1TestBase {

    // MARK: - Resolving the error type

    func test_errorType_fromHeader() async {
        let error = await thrownError(
            response(status: .badRequest, headers: ["X-Amzn-Errortype": "SimpleError"]),
            as: SimpleError.self
        )

        XCTAssertNotNil(error)
    }

    func test_errorType_headerNameIsMatchedCaseInsensitively() async {
        let error = await thrownError(
            response(status: .badRequest, headers: ["x-amzn-errortype": "SimpleError"]),
            as: SimpleError.self
        )

        XCTAssertNotNil(error)
    }

    func test_errorType_fromBodyTypeKey() async {
        let error = await thrownError(
            response(status: .badRequest, body: #"{"__type":"SimpleError"}"#),
            as: SimpleError.self
        )

        XCTAssertNotNil(error)
    }

    func test_errorType_fromBodyCodeKey() async {
        let error = await thrownError(
            response(status: .badRequest, body: #"{"code":"SimpleError"}"#),
            as: SimpleError.self
        )

        XCTAssertNotNil(error)
    }

    func test_errorType_headerTakesPrecedenceOverBody() async {
        let error = await thrownError(
            response(
                status: .badRequest,
                headers: ["X-Amzn-Errortype": "SimpleError"],
                body: #"{"__type":"DetailedError","code":"DetailedError"}"#
            ),
            as: SimpleError.self
        )

        XCTAssertNotNil(error)
    }

    func test_errorType_bodyTypeKeyTakesPrecedenceOverCodeKey() async {
        let error = await thrownError(
            response(status: .badRequest, body: #"{"__type":"SimpleError","code":"DetailedError"}"#),
            as: SimpleError.self
        )

        XCTAssertNotNil(error)
    }

    // The error type may be a shape ID, and may carry trailing metadata after a colon.  Both are
    // stripped before the type is matched to a modeled error.
    // See https://smithy.io/2.0/aws/protocols/aws-restjson1-protocol.html#operation-error-serialization
    func test_errorType_namespaceAndTrailingMetadataAreStripped() async {
        let types = [
            "SimpleError",
            "smithy.swift.tests.RestJSON1Response#SimpleError",
            "SimpleError:http://internal.amazon.com/coral/com.amazon.coral.validate/",
            "smithy.swift.tests.RestJSON1Response#SimpleError:http://internal.amazon.com/coral/",
            "  SimpleError  ",
        ]
        for type in types {
            let error = await thrownError(
                response(status: .badRequest, headers: ["X-Amzn-Errortype": type]),
                as: SimpleError.self
            )
            XCTAssertNotNil(error, "error type \"\(type)\" should resolve to SimpleError")
        }
    }

    func test_errorType_unknownTypeThrowsUnknownHTTPServiceError() async {
        let error = await thrownError(
            response(status: .badRequest, headers: ["X-Amzn-Errortype": "smithy.swift.tests#NotModeledError:extra"]),
            as: UnknownHTTPServiceError.self
        )

        XCTAssertEqual(error?.typeName, "NotModeledError")
    }

    // Error type matching is case sensitive, so a type that differs only in case is not a match.
    func test_errorType_isMatchedCaseSensitively() async {
        let error = await thrownError(
            response(status: .badRequest, headers: ["X-Amzn-Errortype": "simpleerror"]),
            as: UnknownHTTPServiceError.self
        )

        XCTAssertEqual(error?.typeName, "simpleerror")
    }

    func test_errorType_noTypeAnywhereThrowsUnknownHTTPServiceErrorWithNoTypeName() async {
        let error = await thrownError(
            response(status: .internalServerError, body: #"{"unrelated":"field"}"#),
            as: UnknownHTTPServiceError.self
        )

        XCTAssertNil(error?.typeName)
    }

    func test_errorType_emptyBodyThrowsUnknownHTTPServiceErrorWithNoTypeName() async {
        let error = await thrownError(response(status: .internalServerError), as: UnknownHTTPServiceError.self)

        XCTAssertNil(error?.typeName)
    }

    // An error body that isn't JSON, i.e. one produced by an intermediary, is surfaced as an
    // unknown service error carrying the response, and not as a deserialization failure.
    func test_errorType_nonJSONBodyThrowsUnknownHTTPServiceError() async {
        let error = await thrownError(
            response(status: .badGateway, body: "<html><body>502 Bad Gateway</body></html>"),
            as: UnknownHTTPServiceError.self
        )

        XCTAssertNil(error?.typeName)
        XCTAssertEqual(error?.httpResponse.statusCode, .badGateway)
    }

    // MARK: - Deserializing the modeled error body

    func test_modeledError_deserializesAllMembers() async {
        let error = await thrownError(
            response(
                status: .notFound,
                body: #"{"__type":"DetailedError","message":"no such thing","resourceId":"abc123","attempts":3}"#
            ),
            as: DetailedError.self
        )

        XCTAssertEqual(error?.properties.message, "no such thing")
        XCTAssertEqual(error?.properties.resourceId, "abc123")
        XCTAssertEqual(error?.properties.attempts, 3)
    }

    // A live response body is a non-seekable stream that can only be read once.  If the body were
    // read once to find the error type and again to deserialize the error, the modeled error would
    // silently come back with all of its members empty.
    func test_modeledError_deserializesAllMembersFromNonSeekableStream() async {
        let error = await thrownError(
            streamedResponse(
                status: .notFound,
                body: #"{"__type":"DetailedError","message":"no such thing","resourceId":"abc123","attempts":3}"#
            ),
            as: DetailedError.self
        )

        XCTAssertEqual(error?.properties.message, "no such thing")
        XCTAssertEqual(error?.properties.resourceId, "abc123")
        XCTAssertEqual(error?.properties.attempts, 3)
    }

    // The error type comes from the header here, so the body is read only for the error's members.
    func test_modeledError_deserializesAllMembersWhenTypeCameFromHeader() async {
        let error = await thrownError(
            streamedResponse(
                status: .notFound,
                headers: ["X-Amzn-Errortype": "DetailedError"],
                body: #"{"message":"no such thing","resourceId":"abc123","attempts":3}"#
            ),
            as: DetailedError.self
        )

        XCTAssertEqual(error?.properties.message, "no such thing")
        XCTAssertEqual(error?.properties.resourceId, "abc123")
        XCTAssertEqual(error?.properties.attempts, 3)
    }

    func test_modeledError_unmodeledBodyMembersAreIgnored() async {
        let error = await thrownError(
            response(status: .notFound, body: #"{"__type":"DetailedError","nope":{"a":[1,2]}}"#),
            as: DetailedError.self
        )

        XCTAssertNotNil(error)
    }

    func test_modeledError_carriesTheHTTPResponse() async {
        let subject = response(
            status: .notFound,
            headers: ["X-Amzn-Errortype": "DetailedError", "X-Custom": "value"],
            body: #"{"message":"no such thing"}"#
        )

        let error = await thrownError(subject, as: DetailedError.self)

        XCTAssertEqual(error?.httpResponse.statusCode, .notFound)
        XCTAssertEqual(error?.httpResponse.headers.value(for: "X-Custom"), "value")
    }

    // MARK: - Resolving the error message from the body

    func test_message_fromBodyMessageKey() async {
        let error = await thrownError(
            response(status: .badRequest, body: #"{"__type":"SimpleError","message":"from message"}"#),
            as: SimpleError.self
        )

        XCTAssertEqual(error?.message, "from message")
    }

    // Some services send the message under `Message` instead.
    func test_message_fromBodyCapitalizedMessageKey() async {
        let error = await thrownError(
            response(status: .badRequest, body: #"{"__type":"SimpleError","Message":"from Message"}"#),
            as: SimpleError.self
        )

        XCTAssertEqual(error?.message, "from Message")
    }

    // Some services send the message under `errorMessage` instead.
    func test_message_fromBodyErrorMessageKey() async {
        let error = await thrownError(
            response(status: .badRequest, body: #"{"__type":"SimpleError","errorMessage":"from errorMessage"}"#),
            as: SimpleError.self
        )

        XCTAssertEqual(error?.message, "from errorMessage")
    }

    func test_message_bodyKeyPrecedence() async {
        let error = await thrownError(
            response(
                status: .badRequest,
                body: #"{"__type":"SimpleError","message":"a","Message":"b","errorMessage":"c"}"#
            ),
            as: SimpleError.self
        )

        XCTAssertEqual(error?.message, "a")
    }

    // MARK: - Resolving the error message from the headers

    // Services return the message in a header when the response has no body, i.e. for a `HEAD`.
    func test_message_fromErrorMessageHeader() async {
        let error = await thrownError(
            response(
                status: .badRequest,
                headers: ["X-Amzn-Errortype": "SimpleError", "x-amzn-error-message": "from header"]
            ),
            as: SimpleError.self
        )

        XCTAssertEqual(error?.message, "from header")
    }

    // The message header used by event stream errors.
    func test_message_fromEventStreamErrorMessageHeader() async {
        let error = await thrownError(
            response(
                status: .badRequest,
                headers: ["X-Amzn-Errortype": "SimpleError", ":error-message": "from event stream header"]
            ),
            as: SimpleError.self
        )

        XCTAssertEqual(error?.message, "from event stream header")
    }

    // `x-amzn-ErrorMessage`, used by some services, is a distinct header from `x-amzn-error-message`
    // and not merely a difference in case: it has no hyphen between "error" and "message".
    func test_message_fromUnhyphenatedErrorMessageHeader() async {
        let error = await thrownError(
            response(
                status: .badRequest,
                headers: ["X-Amzn-Errortype": "SimpleError", "x-amzn-ErrorMessage": "from unhyphenated header"]
            ),
            as: SimpleError.self
        )

        XCTAssertEqual(error?.message, "from unhyphenated header")
    }

    func test_message_headerPrecedence() async {
        let error = await thrownError(
            response(
                status: .badRequest,
                headers: [
                    "X-Amzn-Errortype": "SimpleError",
                    "x-amzn-error-message": "first",
                    ":error-message": "second",
                    "x-amzn-ErrorMessage": "third",
                ]
            ),
            as: SimpleError.self
        )

        XCTAssertEqual(error?.message, "first")
    }

    func test_message_headerTakesPrecedenceOverBody() async {
        let error = await thrownError(
            response(
                status: .badRequest,
                headers: ["x-amzn-error-message": "from header"],
                body: #"{"__type":"SimpleError","message":"from body"}"#
            ),
            as: SimpleError.self
        )

        XCTAssertEqual(error?.message, "from header")
    }

    // MARK: - Where the resolved message is applied

    // An error whose message is required is pre-filled with an empty string when the response has
    // no body, but the message from the headers is still resolved onto the error.
    func test_message_isResolvedForRequiredMessageErrorWithNoBody() async {
        let error = await thrownError(
            response(
                status: .internalServerError,
                headers: ["X-Amzn-Errortype": "RequiredMessageError", "x-amzn-error-message": "from header"]
            ),
            as: RequiredMessageError.self
        )

        XCTAssertEqual(error?.message, "from header")
    }

    // An error with no modeled `message` member still carries the resolved message.
    func test_message_isResolvedForErrorWithNoMessageMember() async {
        let error = await thrownError(
            response(
                status: .forbidden,
                body: #"{"__type":"NoMessageError","reason":"nope","message":"from body"}"#
            ),
            as: NoMessageError.self
        )

        XCTAssertEqual(error?.properties.reason, "nope")
        XCTAssertEqual(error?.message, "from body")
    }

    func test_message_isNilWhenAbsentEverywhere() async {
        let error = await thrownError(
            response(status: .badRequest, body: #"{"__type":"SimpleError"}"#),
            as: SimpleError.self
        )

        XCTAssertNil(error?.message)
        XCTAssertNil(error?.properties.message)
    }

    // An unknown error carries the message the service sent, and not a client-side diagnostic.
    func test_message_isResolvedForUnknownErrorFromBody() async {
        let error = await thrownError(
            response(status: .badRequest, body: #"{"__type":"NotModeledError","message":"from body"}"#),
            as: UnknownHTTPServiceError.self
        )

        XCTAssertEqual(error?.message, "from body")
        XCTAssertEqual(error?.typeName, "NotModeledError")
    }

    func test_message_isResolvedForUnknownErrorFromHeader() async {
        let error = await thrownError(
            response(
                status: .badRequest,
                headers: ["X-Amzn-Errortype": "NotModeledError", "x-amzn-error-message": "from header"]
            ),
            as: UnknownHTTPServiceError.self
        )

        XCTAssertEqual(error?.message, "from header")
        XCTAssertEqual(error?.typeName, "NotModeledError")
    }

    // An error with no resolvable type still carries the message the service sent.
    func test_message_isResolvedForErrorWithNoType() async {
        let error = await thrownError(
            response(status: .internalServerError, body: #"{"message":"something broke"}"#),
            as: UnknownHTTPServiceError.self
        )

        XCTAssertEqual(error?.message, "something broke")
        XCTAssertNil(error?.typeName)
    }

    func test_message_isNilForUnknownErrorWithNoMessage() async {
        let error = await thrownError(response(status: .internalServerError), as: UnknownHTTPServiceError.self)

        XCTAssertNil(error?.message)
    }
}
