/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public typealias URL = Foundation.URL

extension URL {

    func getQueryItems() -> [SDKURLQueryItem]? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .map { SDKURLQueryItem(name: $0.name, value: $0.value) }
    }
}
