//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
import AwsCommonRuntimeKit
import class Foundation.ProcessInfo

public final class SDKDefaultIO {
    public static let shared = SDKDefaultIO()
    
    public let eventLoopGroup: EventLoopGroup
    public let hostResolver: DefaultHostResolver
    public let clientBootstrap: ClientBootstrap
    public let tlsContext: TlsContext

    private init() {
        AwsCommonRuntimeKit.initialize()
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
        AwsCommonRuntimeKit.cleanup()
    }
}
