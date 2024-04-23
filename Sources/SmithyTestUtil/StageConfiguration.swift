//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

public protocol StageConfiguration: ClientConfiguration {
    var stage: String? { get set }
}
