//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy

public enum SigningPropertyKeys {
    public static let signingName = AttributeKey<String>(name: "SigningName")
    public static let signingRegion = AttributeKey<String>(name: "SigningRegion")
}
