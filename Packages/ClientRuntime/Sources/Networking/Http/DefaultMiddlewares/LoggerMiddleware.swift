//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
public struct LoggerMiddleware<Output: HttpResponseBinding,
                               OutputError: HttpResponseBinding>: Middleware {

    public let id: String = "Logger"

    let clientLogMode: ClientLogMode

    public init(clientLogMode: ClientLogMode) {
        self.clientLogMode = clientLogMode
    }

    public func handle<H>(context: Context,
                          input: SdkHttpRequest,
                          next: H) -> Result<OperationOutput<Output>, SdkError<OutputError>>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context,
          Self.MError == H.MiddlewareError {
        
        guard let logger = context.getLogger() else {
            return next.handle(context: context, input: input)
        }
        
        if clientLogMode == .request || clientLogMode == .requestAndResponse {
            logger.debug("Request: \(input.debugDescription)")
        }
        
        if clientLogMode == .requestWithBody {
            logger.debug("Request: \(input.debugDescriptionWithBody)")
        }
        
        let response = next.handle(context: context, input: input)
        
        do {
            let output = try response.get()
            if clientLogMode == .response || clientLogMode == .requestAndResponse {
                logger.debug("Response: \(output.httpResponse.debugDescription)")
            }
            
            if clientLogMode == .responseWithBody {
                logger.debug("Response: \(output.httpResponse.debugDescriptionWithBody)")
            }
            
        } catch {
            return response
        }
        
        return response
    }

    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<Output>
    public typealias Context = HttpContext
    public typealias MError = SdkError<OutputError>
}
