// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Reacts to the handler's response returned by the recipient of the request
/// message. Deserializes the response into a structured type or error above
/// stacks can react to.
///
/// Should only forward Request to underlying handler.
///
/// Takes Request, and returns result or error.
///
/// Receives raw response, or error from underlying handler.
public struct DeserializeStep<Output: HttpResponseBinding>: MiddlewareStack {
    public typealias Context = HttpContext
 
    public var orderedMiddleware: OrderedGroup<SdkHttpRequest, DeserializeOutput<Output>, HttpContext> = OrderedGroup<SdkHttpRequest, DeserializeOutput<Output>, HttpContext>()
    
    public var id: String = "DeserializeStep"
    
    public typealias MInput = SdkHttpRequest
    
    public typealias MOutput = DeserializeOutput<Output>
}
//to be deleted
//public struct DeserializeStepHandler<Output: HttpResponseBinding>: Handler {
//
//    public typealias Input = SdkHttpRequest
//
//    public typealias Output = DeserializeOutput<Output>
//
//    public func handle(context: HttpContext, input: Input) -> Result<Output, Error> {
//            let decoder = context.getDecoder()
//
//            do {
//                if let httpResponse = context.response {
//                let output = try Output(httpResponse: httpResponse,
//                                        decoder: decoder)
//                return .success(output)
//                } else {
//                    return .failure(ClientError.unknownError("http response was nil for some odd reason"))
//                }
//            } catch let error {
//                return .failure(ClientError.deserializationFailed(error))
//            }
//    }
//}

public struct DeserializeOutput<Output: HttpResponseBinding> {
    var httpResponse: HttpResponse?
    var output: Output?
}
