//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum SmithyHTTPAPI.URLEncodingUtils

// The implementation of these properties has been moved out to
// SmithyHTTPAPI.URLEncodingUtils.
//
// Retroactive extension of Swift standard library & Foundation types is disfavored and
// should be avoided.  These extensions are kept as-is to prevent breaking existing
// generated SDK code, until they are replaced.
extension String {

    /// Encodes a URL component for inclusion in the path or query items, using percent-escaping.
    ///
    /// All characters except alphanumerics plus forward slash, underscore, dash, tilde, and period will be escaped.
    var urlPercentEncodedForPath: String {
        URLEncodingUtils.urlPercentEncodedForPath(self)
    }

    /// Encodes a URL component for inclusion in query item name or value, using percent-escaping.
    ///
    /// All characters except alphanumerics plus forward slash, underscore, dash, tilde, and period will be escaped.
    var urlPercentEncodedForQuery: String {
        URLEncodingUtils.urlPercentEncodedForQuery(self)
    }
}
