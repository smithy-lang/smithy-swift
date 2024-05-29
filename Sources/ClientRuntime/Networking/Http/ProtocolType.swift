/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public typealias Scheme = ProtocolType

public enum ProtocolType: String, CaseIterable {
    case http
    case https
}

/// The raw values correspond to valid Application-Layer Protocol Negotiation (ALPN) Protocol IDs (for example, http/1.1, h2, etc), as defined [here](https://www.iana.org/assignments/tls-extensiontype-values/tls-extensiontype-values.xhtml#alpn-protocol-ids).
public enum ALPNProtocol: String {
    case http1 = "http/1.1"
    case http2 = "h2"
}

extension ProtocolType {
    var port: Int {
        switch self {
        case .http: return 80
        case .https: return 443
        }
    }
}
