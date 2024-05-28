//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy

public extension Context {

    var signingAlgorithm: SigningAlgorithm? {
        get { attributes.get(key: signingAlgorithmKey) }
        set { attributes.set(key: signingAlgorithmKey, value: newValue) }
    }
}

private let signingAlgorithmKey = AttributeKey<SigningAlgorithm>(name: "SigningAlgorithmKey")
