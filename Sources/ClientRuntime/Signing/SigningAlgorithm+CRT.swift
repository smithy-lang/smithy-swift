//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyHTTPAuthAPI
import AwsCommonRuntimeKit

extension SigningAlgorithm {

    /// Convert self to CRT SigningAlgorithmType
    /// - Returns: SigningAlgorithmType
    public func toCRTType() -> SigningAlgorithmType {
        switch self {
        case .sigv4: return .signingV4
        case .sigv4a: return .signingV4Asymmetric
        }
    }
}
