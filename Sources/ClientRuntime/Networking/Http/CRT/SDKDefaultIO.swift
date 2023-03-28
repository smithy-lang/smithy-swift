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
    public let eventLoopGroup: EventLoopGroup
    public let hostResolver: HostResolver
    public let clientBootstrap: ClientBootstrap
    public var tlsContext: TLSContext
    public let logger: Logger

    /// Provide singleton access since we want to share and re-use the instance properties
    public static let shared = SDKDefaultIO()

    private init() {
        CommonRuntimeKit.initialize()
        self.logger = Logger(pipe: stdout, level: .none, allocator: defaultAllocator)

        do {
            self.eventLoopGroup = try EventLoopGroup(threadCount: 0)
        } catch {
            fatalError("""
            Event Loop Group failed to create. This should never happen. Please open a
            Github issue with us at https://github.com/awslabs/aws-sdk-swift.
            """)
        }

        do {
            self.hostResolver = try HostResolver.makeDefault(
                eventLoopGroup: eventLoopGroup,
                maxHosts: 8,
                maxTTL: 30
            )
        } catch {
            fatalError("""
            Host Resolver failed to create. This should never happen. Please open a
            Github issue with us at https://github.com/awslabs/aws-sdk-swift.
            """)
        }

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
    
    public func setAlpnList(_ alpnList: [String]) throws {
        let tlsContextOptions = TLSContextOptions.makeDefault()
        tlsContextOptions.setVerifyPeer(true)
        tlsContextOptions.setAlpnList(alpnList)
        SDKDefaultIO.shared.tlsContext = try TLSContext(options: tlsContextOptions, mode: .client)
    }
}
