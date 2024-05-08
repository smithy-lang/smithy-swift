/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

public struct URI: Hashable {
    public let scheme: String
    public let path: String
    public let host: String
    public let port: Int16
    public let query: [SDKURLQueryItem]
    public let username: String?
    public let password: String?

    public init(scheme: String,
                path: String,
                host: String,
                port: Int16,
                query: [SDKURLQueryItem],
                username: String? = nil,
                password: String? = nil) {
        self.scheme = scheme
        self.path = path
        self.host = host
        self.port = port
        self.query = query
        self.username = username
        self.password = password
    }
}
