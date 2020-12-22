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
        let initializeStep = InitializeStep<Any, Any>()
        let serializeStep = SerializeStep<Any, Any>()
        let buildStep = BuildStep<Any, Any>()
        let finalizeStep = FinalizeStep<Any, Any>()
        let deserializeStep = DeserializeStep<Any, Any>()
        let context = TestContext()
        var stack = OperationStack(id: "Test Operation",
                                   initializeStep: initializeStep,
                                   serializeStep: serializeStep,
                                   buildStep: buildStep,
                                   finalizeStep: finalizeStep,
                                   deserializeStep: deserializeStep)
        stack.initializeStep.intercept(position: .before, middleware: TestMiddleware(id: "TestMiddleware"))

        let result = stack.handleMiddleware(context: context, subject: "I", next: TestHandler())
        
        switch result {
        case .success(let string):
            XCTAssert(string as! String == "I want a dog and a cat")
        case .failure(_):
            XCTFail()
        }
    }
    
    func testMiddlewareStackConvenienceFunction() {
        let initializeStep = InitializeStep<Any, Any>()
        let serializeStep = SerializeStep<Any, Any>()
        let buildStep = BuildStep<Any, Any>()
        let finalizeStep = FinalizeStep<Any, Any>()
        let deserializeStep = DeserializeStep<Any, Any>()
        let context = TestContext()
        var stack = OperationStack(id: "Test Operation",
                                   initializeStep: initializeStep,
                                   serializeStep: serializeStep,
                                   buildStep: buildStep,
                                   finalizeStep: finalizeStep,
                                   deserializeStep: deserializeStep)
        stack.initializeStep.intercept(position: .before, id: "add word") { (context, result) -> Result<Any, Error> in
            return result.map { (original) -> Any in
                return (original as? String ?? "") + " want a dog"
            }
        }

        let result = stack.handleMiddleware(context: context, subject: "I", next: TestHandler())
        
        switch result {
        case .success(let string):
            XCTAssert(string as! String == "I want a dog and a cat")
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
 
 struct TestHandler: Handler {
    func handle(context: MiddlewareContext, result: Result<Any, Error>) -> Result<Any, Error> {
        return result.map { (original) -> String in
            return (original as? String ?? "") + " and a cat"
        }
    }
    
    typealias Input = Any
    
    typealias Output = Any
    
    
 }
 
 struct TestMiddleware: Middleware {
    var id: String
    
    func handle<H>(context: MiddlewareContext, result: Result<Any, Error>, next: H) -> Result<Any, Error> where H : Handler, Self.MInput == H.Input, Self.MOutput == H.Output {
        let result = result.map { (original) -> Any in
            return (original as? String ?? "") + " want a dog"
        }
        return next.handle(context: context, result: result)
    }
    
    typealias MInput = Any
    
    typealias MOutput = Any
    
    
 }

 struct TestContext: MiddlewareContext {
    var attributes: Attributes = Attributes()
 }
