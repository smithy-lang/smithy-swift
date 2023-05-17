/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public typealias URL = Foundation.URL

extension URL {

    func toQueryItems() -> [URLQueryItem]? {
        URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .map { URLQueryItem(name: $0.name, value: $0.value) }
    }
}
