// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Resolves endpoints for a given service and region
public protocol EndpointResolver {
  /// Resolve the `AWSEndpoint` for the given serviceId and region
  func resolve() throws -> Endpoint
}

public struct DefaultEndpointResolver: EndpointResolver {
    let config: SDKRuntimeConfiguration
    
    public init(config: SDKRuntimeConfiguration) {
        self.config = config
    }
    
    public func resolve() throws -> Endpoint {
        return try Endpoint(urlString: config.endpoint!)
    }
}


// TODO: this struct is unfinished. proper endpoint resolving will need to be added futuristically
public struct EndpointResolverMiddleware<OperationStackOutput: HttpResponseBinding,
                                         OperationStackError: HttpResponseBinding>: Middleware {
    
    public let id: String = "EndpointResolver"
    public let endpointResolver: EndpointResolver
    
    public init(endpointResolver: EndpointResolver) {
        self.endpointResolver = endpointResolver
    }
    
    public func handle<H>(context: Context,
                          input: SdkHttpRequestBuilder,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
              
              let endpoint: Endpoint
              do {
                  endpoint = try endpointResolver.resolve()
              } catch {
                  throw SdkError<OperationStackError>.client(ClientError.unknownError(("Endpoint is unable to be resolved")))
              }
              var host = ""
              if let overrideHost = context.getHost() {
                  host = overrideHost
              } else {
                  host = "\(context.getHostPrefix() ?? "")\(endpoint.host)"
              }
              
              if let protocolType = endpoint.protocolType {
                  input.withProtocol(protocolType)
              }
              
              var updatedContext = context
              
              input.withMethod(context.getMethod())
                  .withHost(host)
                  .withPort(endpoint.port)
                  .withPath(context.getPath())
              // TODO: investigate if this header should be the same host value as
              // the actual host and where this header should be set
                  .withHeader(name: "Host", value: host)
              
              return try await next.handle(context: updatedContext, input: input)
              
          }
    
    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
    public typealias MError = SdkError<OperationStackError>
}
