//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
import AwsCommonRuntimeKit
import class Foundation.ProcessInfo
#if os(Linux)
import Glibc
#else
import Darwin
#endif

public final class SDKDefaultIO {
    static weak var privateShared: SDKDefaultIO? = nil
    
    // TODO: revisit this and verify that it is thread safe.
    public static var shared: SDKDefaultIO {
        if let shared = privateShared {
            return shared
        } else {
            let shared = SDKDefaultIO()
            privateShared = shared
            return shared
        }
    }
    
    public var eventLoopGroup: EventLoopGroup
    public var hostResolver: DefaultHostResolver
    public var clientBootstrap: ClientBootstrap
    public var tlsContext: TlsContext
    public var logger: Logger

    private init() {
        AwsCommonRuntimeKit.initialize()
        self.logger = Logger(pipe: stdout, level: .none, allocator: defaultAllocator)
        self.eventLoopGroup = EventLoopGroup(threadCount: 0)
        self.hostResolver = DefaultHostResolver(eventLoopGroup: eventLoopGroup,
                                                maxHosts: 8,
                                                maxTTL: 30)
        
        do {
            self.clientBootstrap = try ClientBootstrap(eventLoopGroup: eventLoopGroup,
                                                       hostResolver: hostResolver)
        } catch {
            fatalError("""
                       Client Bootstrap failed to create. This could be due to lack
                       of memory but should never happen. Please open a Github issue with
                       us at https://github.com/awslabs/aws-sdk-swift.
                       """)
        }
        
        let tlsContextOptions = TlsContextOptions()
        tlsContextOptions.setVerifyPeer(true)
        
        do {
            self.tlsContext = try TlsContext(options: tlsContextOptions,
                                             mode: .client)
        } catch {
            fatalError("""
                        Tls Context failed to create. This should never happen.Please open a
                        Github issue with us at https://github.com/awslabs/aws-sdk-swift.
                        """)
        }
    }
    
    deinit {
        AwsCommonRuntimeKit.cleanUp()
    }
}
