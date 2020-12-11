//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import XCTest
@testable import ClientRuntime

class MiddlewareStackTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    func testMiddlewareStackSuccessInterceptAfter() {
        let testPhase = Phase<TestContext, String, Error>(name: "Test")
        var stack = MiddlewareStack(phases: testPhase)
        stack.intercept(phase: testPhase, position: .after, middleware: TestMiddleware())
        let context = TestContext()
        let result = stack.execute(context: context, subject: "is a cat") { (context, string) -> Result<String, Error> in
            XCTAssert(string == "is now a dog")
            return .success(string)
        }
        switch result {
        case .success(let string):
            XCTAssert(string == "is now a dog")
        case .failure(_):
            XCTFail()
        }
    }
    
    func testMiddlewareStackFailureInterceptAfter() {
        let testPhase = Phase<TestContext, String, Error>(name: "Test")
        var stack = MiddlewareStack(phases: testPhase)
        stack.intercept(phase: testPhase, position: .after, middleware: TestMiddleware())
        let context = TestContext()
        let result = stack.execute(context: context, subject: "is a cat") { (context, string) -> Result<String, Error> in
            XCTAssert(string == "is now a dog")
            let error = MiddlewareError.unknown("an unknown error occurred")
            return .failure(error)
        }
        switch result {
        case .success(_):
            XCTFail()
        case .failure(let error):
            if case let MiddlewareError.unknown(unwrappedError) = error {
                XCTAssert(unwrappedError == "an unknown error occurred")
            }
        }
    }
    
    func testMiddlewareInterceptWithHandlerInterceptAfter() {
        let testPhase = Phase<TestContext, String, Error>(name: "Test")
        var stack = MiddlewareStack(phases: testPhase)
        stack.intercept(testPhase, position: .after) { (context, subject) -> Result<String, Error> in
            var newSubject = subject //copy original subject to new string
            newSubject = "is now a dog" // change original subject
            return .success(newSubject)
        }
        let context = TestContext()
        let result = stack.execute(context: context, subject: "is a cat")
        switch result {
        case .success(let string):
            XCTAssert(string == "is now a dog")
        case .failure(_):
            XCTFail()
        }
    }
    
    func testMiddlewareInterceptWithHandlerInterceptBefore() {
        let testPhase = Phase<TestContext, String, Error>(name: "Test")
        var stack = MiddlewareStack(phases: testPhase)
        stack.intercept(testPhase, position: .before) { (context, subject) -> Result<String, Error> in
            var newSubject = subject //copy original subject to new string
            newSubject = "is a cat" // change original subject
            return .success(newSubject)
        }
        let context = TestContext()
        let result = stack.execute(context: context, subject: "is now a dog")
        switch result {
        case .success(let string):
            XCTAssert(string == "is a cat")
        case .failure(_):
            XCTFail()
        }
    }
}

struct TestMiddleware: Middleware {
    var id: String = "TestMiddleware"
    
    func handle<H>(context: TestContext, subject: String, next: H) -> Result<String, Error> where H : Handler, Self.TContext == H.TContext, Self.TError == H.TError, Self.TSubject == H.TSubject {
        var newSubject = subject //copy original subject to new string
        newSubject = "is now a dog" // change original subject
        return next.handle(context: context, subject: newSubject)
    }
    
    typealias TContext = TestContext
    
    typealias TSubject = String
    
    typealias TError = Error
}

struct TestContext {
}
