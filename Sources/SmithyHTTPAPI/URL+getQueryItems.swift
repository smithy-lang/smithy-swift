//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.URL
import struct Foundation.URLComponents
import struct Smithy.URIQueryItem

public func getQueryItems(url: URL) -> [URIQueryItem]? {
    URLComponents(url: url, resolvingAgainstBaseURL: false)?
        .queryItems?
        .map { URIQueryItem(name: $0.name, value: $0.value) }
}
