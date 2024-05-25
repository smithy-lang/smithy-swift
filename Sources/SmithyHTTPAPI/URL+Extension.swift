/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import struct Foundation.URL
import struct Foundation.URLComponents

extension URL {

    func toQueryItems() -> [SDKURLQueryItem]? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .map { SDKURLQueryItem(name: $0.name, value: $0.value) }
    }
}
