// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import Foundation

public struct MutateHeadersMiddleware<OperationStackOutput: HttpResponseBinding,
                                      OperationStackError: HttpResponseBinding>: Middleware  {
    
    public let id: String = "MutateHeaders"
    
    private var overrides: Headers? = nil
    private var additional: Headers? = nil
    private var conditionallySet: Headers? = nil
    
    public init(overrides: [String: String]? = nil,
                additional: [String: String]? = nil,
                conditionallySet: [String: String]? = nil) {
        if let overrides = overrides {
            self.overrides = Headers(overrides)
        }
        if let additional = additional {
            self.additional = Headers(additional)
        }
        if let conditionallySet = conditionallySet {
            self.conditionallySet = Headers(conditionallySet)
        }
    }
    
    public func handle<H>(context: Context,
                          input: SdkHttpRequestBuilder,
                          next: H) -> Result<OperationOutput<OperationStackOutput>, MError>
    where H: Handler,
    Self.MInput == H.Input,
    Self.MOutput == H.Output,
    Self.Context == H.Context,
    Self.MError == H.MiddlewareError {
        if let additional = additional {
            input.withHeaders(additional)
        }
        
        if let overrides = overrides {
            for header in overrides.headers {
                input.updateHeader(name: header.name, value: header.value)
            }
        }
        
        if let conditionallySet = conditionallySet {
            for header in conditionallySet.headers {
                if !input.headers.exists(name: header.name) {
                    input.headers.add(name: header.name, value: header.value)
                }
            }
        }
        
        return next.handle(context: context, input: input)
    }
    
    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
    public typealias MError = SdkError<OperationStackError>
}
