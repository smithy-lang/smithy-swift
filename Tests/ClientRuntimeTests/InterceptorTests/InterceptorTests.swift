//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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

    struct AddAttributeInterceptor<T, RequestType, ResponseType, AttributesType: HasAttributes> : Interceptor {
        private let key: AttributeKey<T>
        private let value: T

        init(key: AttributeKey<T>, value: T) {
            self.key = key
            self.value = value
        }

        public func modifyBeforeSerialization(context: inout some MutableInput<Self.AttributesType>) async throws {
            let attributes = context.getAttributes()
            attributes.set(key: self.key, value: self.value)
        }
    }

    struct ModifyInputInterceptor<InputType, RequestType, ResponseType, AttributesType: HasAttributes> : Interceptor {
        private let keyPath: WritableKeyPath<InputType, String?>
        private let value: String

        init(keyPath: WritableKeyPath<InputType, String?>, value: String) {
            self.keyPath = keyPath
            self.value = value
        }

        public func modifyBeforeSerialization(context: inout some MutableInput<Self.AttributesType>) async throws {
            var input: InputType = context.getInput()!
            input[keyPath: keyPath] = value
            context.updateInput(updated: input)
        }
    }

    struct AddHeaderInterceptor : HttpInterceptor {
        private let headerName: String
        private let headerValue: String

        init(headerName: String, headerValue: String) {
            self.headerName = headerName
            self.headerValue = headerValue
        }

        public func modifyBeforeTransmit(context: inout some MutableRequest<Self.RequestType, Self.AttributesType>) async throws {
            let builder = context.getRequest().toBuilder()
            builder.withHeader(name: headerName, value: headerValue)
            context.updateRequest(updated: builder.build())
        }
    }

    struct ModifyMultipleInterceptor: HttpInterceptor {
        private let newInputValue: Int

        init(newInputValue: Int) {
            self.newInputValue = newInputValue
        }

        public func modifyBeforeSerialization(context: inout some MutableInput<Self.AttributesType>) async throws {
            var input: TestInput = context.getInput()!
            input.otherProperty = newInputValue
            context.updateInput(updated: input)
        }

        public func modifyBeforeTransmit(context: inout some MutableRequest<Self.RequestType, Self.AttributesType>) async throws {
            let input: TestInput = context.getInput()!
            let builder = context.getRequest().toBuilder()
            builder.withHeader(name: "otherProperty", value: "\(input.otherProperty)")
            context.updateRequest(updated: builder.build())
        }
    }

    func test_mutation() async throws {
        let httpContext = HttpContext(attributes: Attributes())
        let input = TestInput(property: "foo")
        var interceptorContext = DefaultInterceptorContext<SdkHttpRequest, HttpResponse, HttpContext>(input: input, attributes: httpContext)
        let addAttributeInterceptor = AddAttributeInterceptor<String, SdkHttpRequest, HttpResponse, HttpContext>(key: AttributeKey(name: "foo"), value: "bar")
        let modifyInputInterceptor = ModifyInputInterceptor<TestInput, SdkHttpRequest, HttpResponse, HttpContext>(keyPath: \.property, value: "bar")
        let addHeaderInterceptor = AddHeaderInterceptor(headerName: "foo", headerValue: "bar")
        let modifyMultipleInterceptor = ModifyMultipleInterceptor(newInputValue: 1)

        let interceptors: [AnyInterceptor<SdkHttpRequest, HttpResponse, HttpContext>] = [
            addAttributeInterceptor.erase(), 
            modifyInputInterceptor.erase(), 
            addHeaderInterceptor.erase(),
            modifyMultipleInterceptor.erase()
        ]
        for i in interceptors {
            try await i.modifyBeforeSerialization(context: &interceptorContext)
        }
        interceptorContext.updateRequest(updated: SdkHttpRequestBuilder().build())
        for i in interceptors {
            try await i.modifyBeforeTransmit(context: &interceptorContext)
        }

        let updatedInput: TestInput = interceptorContext.getInput()!
        XCTAssertEqual(updatedInput.property, "bar")
        XCTAssertEqual(updatedInput.otherProperty, 1)
        XCTAssertEqual(interceptorContext.getAttributes().get(key: AttributeKey(name: "foo")), "bar")
        XCTAssertEqual(interceptorContext.getRequest().headers.value(for: "foo"), "bar")
        XCTAssertEqual(interceptorContext.getRequest().headers.value(for: "otherProperty"), "1")
    }
}
