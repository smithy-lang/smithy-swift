//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Creates a `CharacterSet` of the characters that need not be percent encoded in the
// resulting URL.  This set consists of alphanumerics plus underscore, dash, tilde, and
// period.  Any other character should be percent-encoded when used in a path segment.
// Forward-slash is added as well because the segments have already been joined into a path.
//
// See, for URL-allowed characters:
// https://www.rfc-editor.org/rfc/rfc3986#section-2.3
private let allowedForPath = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "/_-.~"))
private let allowedForQuery = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-.~"))

extension String {

    /// Encodes a URL component for inclusion in the path or query items, using percent-escaping.
    ///
    /// All characters except alphanumerics plus forward slash, underscore, dash, tilde, and period will be escaped.
    var urlPercentEncodedForPath: String {
        addingPercentEncoding(withAllowedCharacters: allowedForPath) ?? self
    }

    /// Encodes a URL component for inclusion in query item name or value, using percent-escaping.
    ///
    /// All characters except alphanumerics plus forward slash, underscore, dash, tilde, and period will be escaped.
    var urlPercentEncodedForQuery: String {
        addingPercentEncoding(withAllowedCharacters: allowedForQuery) ?? self
    }
}
