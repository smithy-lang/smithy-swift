// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Reprioritize a resolved list of auth options based on a user's preference list
/// - Parameters:
///   - authSchemePreference: List of preferred auth scheme IDs
///   - authOptions: List of auth options to prioritize
/// - Returns: A new list of auth options with preferred options first, followed by non-preferred options
public extension AuthSchemeResolver {
    func reprioritizeAuthOptions(authSchemePreference: [String]?, authOptions: [AuthOption]) -> [AuthOption] {
        // Add preferred candidates first
        let preferredAuthOptions: [AuthOption]

        // For comparison, only use the scheme ID with the namespace prefix trimmed.
        if let authSchemePreference {
            preferredAuthOptions = authSchemePreference.compactMap { preferredSchemeID in
                let preferredSchemeName = normalizedSchemeName(preferredSchemeID)
                return authOptions.first { option in
                    normalizedSchemeName(option.schemeID) == preferredSchemeName
                }
            }
        } else {
            preferredAuthOptions = []
        }

        // Add any remaining candidates that weren't in the preference list
        let nonPreferredAuthOptions = authOptions.filter { option in
            !preferredAuthOptions.contains { preferred in
                normalizedSchemeName(preferred.schemeID) == normalizedSchemeName(option.schemeID)
            }
        }

        return preferredAuthOptions + nonPreferredAuthOptions
    }

    // Trim namespace prefix from scheme ID
    // Ex. aws.auth#sigv4 -> sigv4
    func normalizedSchemeName(_ schemeID: String) -> String {
        return schemeID.split(separator: "#").last.map(String.init) ?? schemeID
    }
}
