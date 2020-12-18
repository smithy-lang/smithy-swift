 // Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 // SPDX-License-Identifier: Apache-2.0.

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
        let initializeStep = InitializeStep<String, Error>()
        let serializeStep = SerializeStep<String, Error>()
        let buildStep = BuildStep<String, Error>()
        let finalizeStep = FinalizeStep<String, Error>()
        let deserializeStep = DeserializeStep<String, Error>()
        let context = TestContext()
        let stack = OperationStack(id: "Test Operation",
                                   initializeStep: initializeStep,
                                   serializeStep: serializeStep,
                                   buildStep: buildStep,
                                   finalizeStep: finalizeStep,
                                   deserializeStep: deserializeStep)
        let result = stack.handleMiddleware(context: context, subject: "is a cat", next: TestHandler())
        
        switch result {
        case .success(let string):
            XCTAssert(string == "is now a dog")
        case .failure(_):
            XCTFail()
        }
    }
//
//    func testMiddlewareStackFailureInterceptAfter() {
//        let testPhase = Phase<TestContext, String, Error>(name: "Test")
//        var stack = MiddlewareStack(phases: testPhase)
//        stack.intercept(phase: testPhase, position: .after, middleware: TestMiddleware())
//        let context = TestContext()
//        let result = stack.execute(context: context, subject: "is a cat") { (context, result) -> Result<String, Error> in
//            let error = MiddlewareError.unknown("an unknown error occurred")
//            return .failure(error)
//        }
//        switch result {
//        case .success(_):
//            XCTFail()
//        case .failure(let error):
//            if case let MiddlewareError.unknown(unwrappedError) = error {
//                XCTAssert(unwrappedError == "an unknown error occurred")
//            }
//        }
//    }
//
//    func testMiddlewareInterceptWithHandlerInterceptAfter() {
//        let testPhase = Phase<TestContext, String, Error>(name: "Test")
//        var stack = MiddlewareStack(phases: testPhase)
//        stack.intercept(testPhase, position: .after, id: "AfterTest") { (context, result) -> Result<String, Error> in
//            result.map { (subject) -> String in
//                var newSubject = subject //copy original subject to new string
//                newSubject = "is now a dog" // change original subject
//                return newSubject
//            }
//        }
//        let context = TestContext()
//        let result = stack.execute(context: context, subject: "is a cat")
//        switch result {
//        case .success(let string):
//            XCTAssert(string == "is now a dog")
//        case .failure(_):
//            XCTFail()
//        }
//    }
//
//    func testMiddlewareInterceptWithHandlerInterceptBefore() {
//        let testPhase = Phase<TestContext, String, Error>(name: "Test")
//        var stack = MiddlewareStack(phases: testPhase)
//        stack.intercept(testPhase, position: .before, id: "BeforeTest") { (context, result) -> Result<String, Error> in
//            return result.map { (subject) -> String in
//                var newSubject = subject //copy original subject to new string
//                newSubject = "is a cat" // change original subject
//                return newSubject
//            }
//        }
//        let context = TestContext()
//        let result = stack.execute(context: context, subject: "is now a dog")
//        switch result {
//        case .success(let string):
//            XCTAssert(string == "is a cat")
//        case .failure(_):
//            XCTFail()
//        }
//    }
}

//struct TestMiddleware: Middleware {
//    func handle<H>(context: TestContext, result: Result<String, Error>, next: H) -> Result<String, Error> where H : Handler, Self.TContext == H.TContext, Self.TError == H.TError, Self.TSubject == H.TSubject {
//        return result.flatMap { (subject) -> Result<String, Error> in
//            var newSubject = subject //copy original subject to new string
//            newSubject = "is now a dog" // change original subject
//            return next.handle(context: context, result: .success(newSubject))
//        }
//    }
//
//    var id: String = "TestMiddleware"
//
//    typealias TContext = TestContext
//
//    typealias TSubject = String
//
//    typealias TError = Error
//}
 
 struct TestHandler: Handler {
    func handle(context: MiddlewareContext, result: Result<String, Error>) -> Result<String, Error> {
        return result.map { (original) -> String in
            return "is now a dog"
        }
    }
    
    typealias TSubject = String
    
    typealias TError = Error
    
    
 }

 struct TestContext: MiddlewareContext {
    var attributes: Attributes = Attributes()
 }
