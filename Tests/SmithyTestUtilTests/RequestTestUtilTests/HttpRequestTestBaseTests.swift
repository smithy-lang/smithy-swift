/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Smithy
import SmithyHTTPAPI
import SmithyReadWrite
import SmithyJSON
import SmithyTestUtil
import ClientRuntime
import XCTest

class HttpRequestTestBaseTests: HttpRequestTestBase {
    static let host = "myapi.host.com"

    public struct SayHelloInputURLHostMiddleware: RequestMessageSerializer {
        public typealias InputType = SayHelloInput
        public typealias RequestType = HTTPRequest

        public let id: Swift.String = "SayHelloInputURLHostMiddleware"

        let host: Swift.String?

        public init(host: Swift.String? = nil) {
            self.host = host
        }

        public func apply(input: SayHelloInput, builder: HTTPRequestBuilder, attributes: Context) throws {
            if let host = host {
                attributes.host = host
            }
        }
    }

    struct SayHelloInputQueryItemMiddleware: RequestMessageSerializer {
        public typealias InputType = SayHelloInput
        public typealias RequestType = HTTPRequest

        var id: String = "SayHelloInputQueryItemMiddleware"

        public func apply(input: HttpRequestTestBaseTests.SayHelloInput, builder: HTTPRequestBuilder, attributes: Context) throws {
            if let requiredQuery = input.requiredQuery {
                builder.withQueryItem(URIQueryItem(name: "RequiredQuery".urlPercentEncoding(), value: String(requiredQuery).urlPercentEncoding()))
            }
        }
    }

    struct SayHelloInputHeaderMiddleware: RequestMessageSerializer {
        public typealias InputType = SayHelloInput
        public typealias RequestType = HTTPRequest

        var id: String = "SayHelloInputHeaderMiddleware"

        func apply(input: InputType, builder: RequestType.RequestBuilderType, attributes: Context) throws {
            builder.headers.add(name: "Content-Type", value: "application/json")
            if let requiredHeader = input.requiredHeader {
                builder.headers.add(name: "RequiredHeader", value: requiredHeader)
            }
        }
    }

    struct SayHelloInputBodyMiddleware: RequestMessageSerializer {
        public typealias InputType = SayHelloInput
        public typealias RequestType = HTTPRequest

        var id: String = "SayHelloInputBodyMiddleware"

        let rootNodeInfo: SmithyJSON.Writer.NodeInfo
        let inputWritingClosure: WritingClosure<SayHelloInput, SmithyJSON.Writer>

        public init(
            rootNodeInfo: SmithyJSON.Writer.NodeInfo,
            inputWritingClosure: @escaping WritingClosure<SayHelloInput, SmithyJSON.Writer>
        ) {
            self.rootNodeInfo = rootNodeInfo
            self.inputWritingClosure = inputWritingClosure
        }

        func apply(input: InputType, builder: RequestType.RequestBuilderType, attributes: Context) throws {
            let writer = SmithyJSON.Writer(nodeInfo: rootNodeInfo)
            try writer.write(input, with: inputWritingClosure)
            let body = ByteStream.data(try writer.data())
            builder.withBody(body)
        }
    }

    struct SayHelloInput: Encodable {

        let greeting: String?
        let forbiddenQuery: String?
        let requiredQuery: String?
        let forbiddenHeader: String?
        let requiredHeader: String?

        init(greeting: String? = nil,
             forbiddenQuery: String? = nil,
             requiredQuery: String? = nil,
             forbiddenHeader: String? = nil,
             requiredHeader: String? = nil) {
            self.greeting = greeting
            self.forbiddenQuery = forbiddenQuery
            self.requiredQuery = requiredQuery
            self.forbiddenHeader = forbiddenHeader
            self.requiredHeader = requiredHeader
        }

        private enum CodingKeys: String, CodingKey {
            case greeting
        }

        static func write(value: SayHelloInput, to writer: SmithyJSON.Writer) throws {
            try writer["greeting"].write(value.greeting)
        }
    }

    // Mocks the code-generated unit test which includes testing for forbidden/required headers/queries
    func testSayHello() async throws {
        let expected = buildExpectedHttpRequest(method: .post,
                                                path: "/",
                                                headers: ["Content-Type": "application/json",
                                                          "RequiredHeader": "required header"],
                                                requiredQueryParams: ["RequiredQuery=required%20query"],
                                                body: .data("{\"greeting\": \"Hello There\"}".data(using: .utf8)!),
                                                host: HttpRequestTestBaseTests.host,
                                                resolvedHost: nil)

        let input = SayHelloInput(greeting: "Hello There",
                                  forbiddenQuery: "forbidden query",
                                  requiredQuery: "required query",
                                  forbiddenHeader: "forbidden header",
                                  requiredHeader: "required header")

        let builder = TestOrchestrator.httpBuilder()
            .attributes(ContextBuilder().withMethod(value: .post).build())
            .serialize(SayHelloInputURLHostMiddleware(host: HttpRequestTestBaseTests.host))
            .serialize(SayHelloInputQueryItemMiddleware())
            .serialize(SayHelloInputHeaderMiddleware())
            .serialize(SayHelloInputBodyMiddleware(rootNodeInfo: "", inputWritingClosure: SayHelloInput.write(value:to:)))
            .applyEndpoint({ request, _, attributes in
                return request.toBuilder()
                    .withMethod(attributes.method)
                    .withHost("\(attributes.hostPrefix ?? "")\(attributes.host ?? "")")
                    .build()
            })
            .deserialize(MockDeserializeMiddleware<MockOutput>(id: "TestDeserializeMiddleware", responseClosure: { _ in MockOutput() }))
            .executeRequest({ actual, attributes in
                let forbiddenQueryParams = ["ForbiddenQuery"]
                for forbiddenQueryParam in forbiddenQueryParams {
                    XCTAssertFalse(
                        self.queryItemExists(forbiddenQueryParam, in: actual.destination.queryItems),
                        "Forbidden Query:\(forbiddenQueryParam) exists in query items"
                    )
                }
                let forbiddenHeaders = ["ForbiddenHeader"]
                for forbiddenHeader in forbiddenHeaders {
                    XCTAssertFalse(self.headerExists(forbiddenHeader, in: actual.headers.headers),
                                   "Forbidden Header:\(forbiddenHeader) exists in headers")
                }

                let requiredQueryParams = ["RequiredQuery"]
                for requiredQueryParam in requiredQueryParams {
                    XCTAssertTrue(self.queryItemExists(requiredQueryParam, in: actual.destination.queryItems),
                                  "Required Query:\(requiredQueryParam) does not exist in query items")
                }

                let requiredHeaders = ["RequiredHeader"]
                for requiredHeader in requiredHeaders {
                    XCTAssertTrue(self.headerExists(requiredHeader, in: actual.headers.headers),
                                  "Required Header:\(requiredHeader) does not exist in headers")
                }

                try await self.assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) throws -> Void in
                    XCTAssertNotNil(actualHttpBody, "The actual ByteStream is nil")
                    XCTAssertNotNil(expectedHttpBody, "The expected ByteStream is nil")
                    try await self.genericAssertEqualHttpBodyData(expected: expectedHttpBody!, actual: actualHttpBody!, contentType: .json)
                })

                return HTTPResponse(body: ByteStream.noStream, statusCode: .ok)
            })

        _ = try await builder.build().execute(input: input)
    }
}
