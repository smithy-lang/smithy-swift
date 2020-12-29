// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

//public struct DeserializeMiddleware<Output: HttpResponseBinding>: Middleware {
//    
//    public var id: String = "Deserialize"
//    
//    public init() {}
//    
//    public func handle<H>(context: HttpResponseContext,
//                          result: Result<Any, Error>,
//                          next: H) -> Result<Any, Error> where H: Handler,
//                                                               Self.TContext == H.TContext,
//                                                               Self.TError == H.TError,
//                                                               Self.TSubject == H.TSubject {
//        return result.flatMap { (_) -> Result<Any, Error> in
//            let decoder = context.getDecoder()
//            let httpResponse = context.response
//            do {
//                let output = try Output(httpResponse: httpResponse,
//                                        decoder: decoder)
//                return next.handle(context: context, result: .success(output))
//            } catch let error {
//                return next.handle(context: context, result: .failure(ClientError.deserializationFailed(error)))
//            }
//        }
//    }
//    
//    public typealias TContext = HttpResponseContext
//    
//    public typealias TSubject = Any
//    
//    public typealias TError = Error
//}
