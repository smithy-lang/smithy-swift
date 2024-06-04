//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import struct Smithy.AttributeKey

public extension Context {

    var messageEncoder: MessageEncoder? {
        get { attributes.get(key: messageEncoderKey) }
        set { attributes.set(key: messageEncoderKey, value: newValue) }
    }
}

private let messageEncoderKey = AttributeKey<MessageEncoder>(name: "MessageEncoderKey")
