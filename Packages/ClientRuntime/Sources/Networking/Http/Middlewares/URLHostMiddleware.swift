//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct URLHostMiddleware<OperationStackInput: Encodable,
                                OperationStackOutput: HttpResponseBinding,
                                OperationStackError: HttpResponseBinding>: Middleware {
    public let id: String = "\(String(describing: OperationStackInput.self))URLHostMiddleware"
    
    let host: String?
    let hostPrefix: String?
    
    public init(host: String? = nil, hostPrefix: String? = nil) {
        self.host = host
        self.hostPrefix = hostPrefix
    }
    
    public func handle<H>(context: Context,
                          input: MInput,
                          next: H) -> Result<MOutput, MError>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context,
          Self.MError == H.MiddlewareError {
              var copiedContext = context
              if let host = host {
                  copiedContext.attributes.set(key: AttributeKey<String>(name: "Host"),
                                               value: host)
              }
              if let hostPrefix = hostPrefix {
                  copiedContext.attributes.set(key: AttributeKey<String>(name: "HostPrefix"),
                                               value: hostPrefix)
              }
              return next.handle(context: copiedContext, input: input)
          }
    
    public typealias MInput = OperationStackInput
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
    public typealias MError = SdkError<OperationStackError>
}
