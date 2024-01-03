//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension URLSessionConfiguration {

    public static func from(httpClientConfiguration: HttpClientConfiguration) -> URLSessionConfiguration {
        var config = URLSessionConfiguration.default
        if let connectTimeout = httpClientConfiguration.connectTimeout {
            config.timeoutIntervalForRequest = connectTimeout
        }
        return config
    }
}
