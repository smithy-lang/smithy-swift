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
    public var eventLoopGroup: EventLoopGroup
    public var hostResolver: HostResolver
    public var clientBootstrap: ClientBootstrap
    public var tlsContext: TLSContext
    public var logger: Logger
    
    /// This class is responsible for setting up and tearing down the CommonRuntimeKit
    /// This should only execute once per application life.
    private struct CommonRuntimeExecuter {
        init() {
            CommonRuntimeKit.initialize()
        }
        func start() {
            // no-op here, we just need to expose a method to call to ensure our
            // static property gets assigned.
        }
    }
    private static let commonRuntimeExecuter = CommonRuntimeExecuter()

    public init() throws {
        SDKDefaultIO.commonRuntimeExecuter.start()
        self.logger = Logger(pipe: stdout, level: .none, allocator: defaultAllocator)
        self.eventLoopGroup = try EventLoopGroup(threadCount: 0)
        self.hostResolver = try HostResolver.makeDefault(
            eventLoopGroup: eventLoopGroup,
            maxHosts: 8,
            maxTTL: 30
        )
        
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
        
        let tlsContextOptions = TLSContextOptions.makeDefault()
        tlsContextOptions.setVerifyPeer(true)
        
        do {
            self.tlsContext = try TLSContext(options: tlsContextOptions,
                                             mode: .client)
        } catch {
            fatalError("""
                        Tls Context failed to create. This should never happen.Please open a
                        Github issue with us at https://github.com/awslabs/aws-sdk-swift.
                        """)
        }
    }
}
