// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct HttpResponseMiddleware<OutputError: HttpResponseBinding>: Middleware {
    
    public var id: String = "Deserialize"
    
    public init() {}
    
    public func handle<H>(context: HttpResponseContext, result: Result<Any, Error>, next: H) -> Result<Any, Error> where H: Handler, Self.TContext == H.TContext, Self.TError == H.TError, Self.TSubject == H.TSubject {
        let decoder = context.getDecoder()
        let httpResponse = context.response
        if (200..<300).contains(httpResponse.statusCode.rawValue) {
            return next.handle(context: context, result: result) //pass it through if success
        } else {
            do {
                let error = try OutputError(httpResponse: httpResponse,
                                            decoder: decoder)
                return next.handle(context: context, result: .failure(SdkError.service(error)))
                
            } catch let error {
                return next.handle(context: context, result: .failure(ClientError.deserializationFailed(error)))
            }
        }
    }
    
    public typealias TContext = HttpResponseContext
    
    public typealias TSubject = Any
    
    public typealias TError = Error
}
