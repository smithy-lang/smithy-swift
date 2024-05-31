//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum URIScheme: String, CaseIterable {
    case http
    case https

    public var port: Int {
        switch self {
        case .http: return 80
        case .https: return 443
        }
    }
}
