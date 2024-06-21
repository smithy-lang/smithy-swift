//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import XCTest
@testable import ClientRuntime

class InterceptorTests: XCTestCase {
    struct TestInput {
        public var property: String?
        public var otherProperty: Int = 0
    }

    struct TestOutput {
        public var property: String?
    }

    struct AddAttributeInterceptor<T, InputType, OutputType, RequestType: RequestMessage, ResponseType: ResponseMessage>: Interceptor {
        private let key: AttributeKey<T>
        private let value: T

        init(key: AttributeKey<T>, value: T) {
            self.key = key
            self.value = value
        }

        public func modifyBeforeSerialization(context: some MutableInput<InputType>) async throws {
            let attributes = context.getAttributes()
            attributes.set(key: self.key, value: self.value)
        }
    }

    struct ModifyInputInterceptor<InputType, OutputType, RequestType: RequestMessage, ResponseType: ResponseMessage>: Interceptor {
        private let keyPath: WritableKeyPath<InputType, String?>
        private let value: String

        init(keyPath: WritableKeyPath<InputType, String?>, value: String) {
            self.keyPath = keyPath
            self.value = value
        }

        public func modifyBeforeSerialization(context: some MutableInput<Self.InputType>) async throws {
            var input = context.getInput()
            input[keyPath: keyPath] = value
            context.updateInput(updated: input)
        }
    }

    struct AddHeaderInterceptor<InputType, OutputType>: HttpInterceptor {
        private let headerName: String
        private let headerValue: String

        init(headerName: String, headerValue: String) {
            self.headerName = headerName
            self.headerValue = headerValue
        }

        public func modifyBeforeTransmit(context: some MutableRequest<Self.InputType, Self.RequestType>) async throws {
            let builder = context.getRequest().toBuilder()
            builder.withHeader(name: headerName, value: headerValue)
            context.updateRequest(updated: builder.build())
        }
    }

    struct ModifyMultipleInterceptor: HttpInterceptor {
        public typealias InputType = TestInput
        public typealias OutputType = TestOutput

        private let newInputValue: Int

        init(newInputValue: Int) {
            self.newInputValue = newInputValue
        }

        public func modifyBeforeSerialization(context: some MutableInput<Self.InputType>) async throws {
            var input = context.getInput()
            input.otherProperty = newInputValue
            context.updateInput(updated: input)
        }

        public func modifyBeforeTransmit(context: some MutableRequest<Self.InputType, Self.RequestType>) async throws {
            let input: TestInput = try XCTUnwrap(context.getInput())
            let builder = context.getRequest().toBuilder()
            builder.withHeader(name: "otherProperty", value: "\(input.otherProperty)")
            context.updateRequest(updated: builder.build())
        }
    }

    func test_mutation() async throws {
        let httpContext = Context(attributes: Attributes())
        let input = TestInput(property: "foo")
        let interceptorContext = DefaultInterceptorContext<TestInput, TestOutput, SdkHttpRequest, HttpResponse>(input: input, attributes: httpContext)
        let addAttributeInterceptor = AddAttributeInterceptor<String, TestInput, TestOutput, SdkHttpRequest, HttpResponse>(key: AttributeKey(name: "foo"), value: "bar")
        let modifyInputInterceptor = ModifyInputInterceptor<TestInput, TestOutput, SdkHttpRequest, HttpResponse>(keyPath: \.property, value: "bar")
        let addHeaderInterceptor = AddHeaderInterceptor<TestInput, TestOutput>(headerName: "foo", headerValue: "bar")
        let modifyMultipleInterceptor = ModifyMultipleInterceptor(newInputValue: 1)

        let interceptors: [AnyInterceptor<TestInput, TestOutput, SdkHttpRequest, HttpResponse>] = [
            addAttributeInterceptor.erase(),
            modifyInputInterceptor.erase(),
            addHeaderInterceptor.erase(),
            modifyMultipleInterceptor.erase()
        ]
        for i in interceptors {
            try await i.modifyBeforeSerialization(context: interceptorContext)
        }
        interceptorContext.updateRequest(updated: SdkHttpRequestBuilder().build())
        for i in interceptors {
            try await i.modifyBeforeTransmit(context: interceptorContext)
        }

        let updatedInput = interceptorContext.getInput()
        XCTAssertEqual(updatedInput.property, "bar")
        XCTAssertEqual(updatedInput.otherProperty, 1)
        XCTAssertEqual(interceptorContext.getAttributes().attributes.get(key: AttributeKey(name: "foo")), "bar")
        XCTAssertEqual(interceptorContext.getRequest().headers.value(for: "foo"), "bar")
        XCTAssertEqual(interceptorContext.getRequest().headers.value(for: "otherProperty"), "1")
    }

    struct ModifyHostInterceptor<InputType, OutputType, RequestType: RequestMessage, ResponseType: ResponseMessage>: Interceptor {
        func modifyBeforeRetryLoop(context: some MutableRequest<Self.InputType, Self.RequestType>) async throws {
            context.updateRequest(updated: context.getRequest().toBuilder().withHost("foo").build())
        }
    }

    struct ModifyHostInterceptorProvider: InterceptorProvider {
        func create<InputType, OutputType, RequestType: RequestMessage, ResponseType: ResponseMessage>() -> any Interceptor<InputType, OutputType, RequestType, ResponseType> {
            ModifyHostInterceptor()
        }
    }

    func test_providers() async throws {
        let provider1 = ModifyHostInterceptorProvider()
        var interceptors = Interceptors<TestInput, TestOutput, SdkHttpRequest, HttpResponse>()

        interceptors.add(provider1.create())

        let attributes = Context(attributes: Attributes())
        let input = TestInput()

        let context = DefaultInterceptorContext<TestInput, TestOutput, SdkHttpRequest, HttpResponse>(input: input, attributes: attributes)
        context.updateRequest(updated: SdkHttpRequestBuilder().build())

        try await interceptors.modifyBeforeSerialization(context: context)
        try await interceptors.modifyBeforeRetryLoop(context: context)
        try await interceptors.modifyBeforeTransmit(context: context)

        let resultRequest = try XCTUnwrap(context.getRequest())

        XCTAssertEqual(resultRequest.host, "foo")
    }
}
