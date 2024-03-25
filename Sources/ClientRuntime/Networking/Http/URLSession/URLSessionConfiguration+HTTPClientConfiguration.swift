//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(watchOS) || os(tvOS) || os(visionOS)

import class Foundation.URLSessionConfiguration

extension URLSessionConfiguration {

    public static func from(httpClientConfiguration: HttpClientConfiguration) -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        if let socketTimeout = httpClientConfiguration.socketTimeout {
            config.timeoutIntervalForRequest = socketTimeout
        }
        return config
    }
}

#endif
