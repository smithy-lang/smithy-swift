//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.

import AwsCommonRuntimeKit
import Foundation

public class CRTClientEngine: HttpClientEngine {
    //TODO: implement Logger
    private var connectionPools: [Endpoint: HttpClientConnectionManager] = [:]
    //constants needed
    private static var HOST_HEADER = "Host"
    private static var CONTENT_LENGTH = "Content-Length"
    private static var CONNECTION = "Connection"
    private static var KEEP_ALIVE = "keep-alive"
    private static var AWS_COMMON_RUNTIME = "AwsCommonRuntime"
    private static var DEFAULT_STREAM_WINDOW_SIZE = 16 * 1024 * 1024 // 16 MB
    
    private let bootstrap: ClientBootstrap
    private let socketOptions: SocketOptions
    private let tlsContextOptions: TlsContextOptions
    private let tlsContext: TlsContext
    private let windowSize: Int
    private let maxConnectionsPerEndpoint: Int
    
    public init(config: CRTClientEngineConfig = CRTClientEngineConfig()) throws {
        AwsCommonRuntimeKit.initialize()
        self.maxConnectionsPerEndpoint = config.maxConnectionsPerEndpoint
        let elg = EventLoopGroup(threadCount: 1)
        let hostResolver = DefaultHostResolver(eventLoopGroup: elg, maxHosts: 8, maxTTL: 30)
        self.bootstrap = try ClientBootstrap(eventLoopGroup: elg, hostResolver: hostResolver)
        self.socketOptions = SocketOptions(socketType: .stream)
        let tlsContextOptions = TlsContextOptions()
        tlsContextOptions.setVerifyPeer(config.verifyPeer)
        self.tlsContextOptions = tlsContextOptions
        self.tlsContext = try TlsContext(options: tlsContextOptions, mode: .client)
        self.windowSize = config.windowSize
    }
    
    private func createConnectionPool(endpoint: Endpoint) -> HttpClientConnectionManager {
        let tlsConnectionOptions = tlsContext.newConnectionOptions()
        let options = HttpClientConnectionOptions(clientBootstrap: bootstrap,
                                                  hostName: endpoint.host,
                                                  initialWindowSize: windowSize,
                                                  port: UInt16(endpoint.port),
                                                  proxyOptions: nil,
                                                  socketOptions: socketOptions,
                                                  tlsOptions: tlsConnectionOptions,
                                                  monitoringOptions: nil,
                                                  maxConnections: maxConnectionsPerEndpoint,
                                                  enableManualWindowManagement: true)
        return HttpClientConnectionManager(options: options)
    }
    
    private func getOrCreateConnectionPool(endpoint: Endpoint) -> HttpClientConnectionManager {
        var connectionPool = connectionPools[endpoint]
        
        if connectionPool == nil {
            let newConnectionPool = createConnectionPool(endpoint: endpoint)
            connectionPools[endpoint] = newConnectionPool //save in dictionary
            connectionPool = newConnectionPool
        }
        
        return connectionPool!
    }
    
    private func addHttpHeaders(endpoint: Endpoint, request: AsyncRequest) throws -> HttpRequest {
        
        var headers = request.headers
        if headers.value(for: CRTClientEngine.HOST_HEADER) == nil {
            headers.add(name: CRTClientEngine.HOST_HEADER, value: endpoint.host)
        }
        
        if headers.value(for: CRTClientEngine.CONNECTION) == nil {
            headers.add(name: CRTClientEngine.CONNECTION, value: CRTClientEngine.KEEP_ALIVE)
        }
        let contentLength = try request.body.map { (body) -> String in
            switch body {
            case .data(let data):
                return String(data?.count ?? 0)
            case .stream(let stream):
                let data = try stream?.readData(maxLength: CRTClientEngine.DEFAULT_STREAM_WINDOW_SIZE)
                return String(data?.count ?? 0)
            default:
                return String(0)
            }
        } ?? "0"
        if headers.value(for: CRTClientEngine.CONTENT_LENGTH) == nil {
            headers.add(name: CRTClientEngine.CONTENT_LENGTH, value: contentLength)
        }
        request.headers = headers
        return try request.toHttpRequest()
    }
    
    public func execute(request: AsyncRequest, completion: @escaping NetworkResult) {
        let connectionMgr = getOrCreateConnectionPool(endpoint: request.endpoint)
        connectionMgr.acquireConnection().then { (result) in
            switch result {
            case .success(let connection):
                do {
                let (requestOptions, future) = try self.makeHttpRequestOptions(request)
                let stream = connection.makeRequest(requestOptions: requestOptions)
                stream.activate()
                future.then { (result) in
                    switch result{
                    case .success(let response):
                        let statusCode = Int(stream.getResponseStatusCode())
                        response.statusCode = HttpStatusCode(rawValue: statusCode) ?? HttpStatusCode.notFound
                        completion(.success(response))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                    
                }
                } catch (let err) {
                    completion(.failure(err))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }

    }
    
    public func close() {
        for (_, value) in connectionPools {
            value.closePendingConnections()
        }
    }
    
    
    public func makeHttpRequestOptions(_ request: AsyncRequest) throws -> (HttpRequestOptions, Future<HttpResponse>) {
        let future = Future<HttpResponse>()
        let response = HttpResponse()

        let requestWithHeaders =  try addHttpHeaders(endpoint: request.endpoint, request: request)
        var incomingData = Data()
        let requestOptions = HttpRequestOptions(request: requestWithHeaders) { (stream, headerBlock, httpHeaders) in
            response.statusCode = HttpStatusCode(rawValue: Int(stream.getResponseStatusCode())) ?? HttpStatusCode.notFound
            response.headers.addAll(httpHeaders: httpHeaders)
        } onIncomingHeadersBlockDone: { (stream, headerBlock) in
            response.statusCode = HttpStatusCode(rawValue: Int(stream.getResponseStatusCode())) ?? HttpStatusCode.notFound
            print(headerBlock)
        } onIncomingBody: { (stream, data) in
            incomingData.append(data)
            
        } onStreamComplete: { (stream, error) in
           
            if case let CRTError.crtError(unwrappedError) = error {
                if unwrappedError.errorCode != 0 {
                    future.fail(error)
                }
            }
            response.content = ResponseType.data(incomingData)
            future.fulfill(response)
        }
        
        return (requestOptions, future)
    }
    
    deinit {
        AwsCommonRuntimeKit.cleanUp()
    }
}
