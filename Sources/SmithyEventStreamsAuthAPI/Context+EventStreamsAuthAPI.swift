//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.AttributeKey
import class Smithy.Context

public extension Context {

    var messageSigner: MessageSigner? {
        get { get(key: messageSignerKey) }
        set { set(key: messageSignerKey, value: newValue) }
    }
}

private let messageSignerKey = AttributeKey<MessageSigner>(name: "MessageSignerKey")
