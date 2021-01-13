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
public struct DeserializeStep<Output: HttpResponseBinding, OutputError: HttpResponseBinding>: MiddlewareStack {
    
    public typealias Context = HttpContext
 
    public var orderedMiddleware: OrderedGroup<SdkHttpRequest,
                                               DeserializeOutput<Output, OutputError>,
                                               HttpContext> = OrderedGroup<SdkHttpRequest,
                                                                           DeserializeOutput<Output, OutputError>,
                                                                           HttpContext>()
    
    public var id: String = "DeserializeStep"
    
    public typealias MInput = SdkHttpRequest
    
    public typealias MOutput = DeserializeOutput<Output, OutputError>
}

// create a special output for this last step to link this step with the final handler and properly return the result
public struct DeserializeOutput<Output: HttpResponseBinding, OutputError: HttpResponseBinding> {
    var httpResponse: HttpResponse?
    var output: Output?
    var error: OutputError?
}
