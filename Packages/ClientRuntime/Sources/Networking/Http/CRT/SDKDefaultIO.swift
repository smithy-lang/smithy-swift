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
    
    // swiftlint:disable force_try
    private init() {
        self.eventLoopGroup = EventLoopGroup(threadCount: UInt16(ProcessInfo.processInfo.activeProcessorCount))
        self.hostResolver = DefaultHostResolver(eventLoopGroup: eventLoopGroup, maxHosts: 8, maxTTL: 30)
        self.clientBootstrap = try! ClientBootstrap(eventLoopGroup: eventLoopGroup, hostResolver: hostResolver)
        let tlsContextOptions = TlsContextOptions()
        tlsContextOptions.setVerifyPeer(true)
        self.tlsContext = try! TlsContext(options: tlsContextOptions, mode: .client)
    }
}
