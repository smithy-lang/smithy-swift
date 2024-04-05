//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyReadWrite.SmithyWriter

extension SmithyWriter {

    public func write(_ value: ByteStream?) throws {
        // This serialization will never be performed in practice, since
        // a ByteStream will never be a part of
        // a XML body - if there is a streaming member in a restXml
        // input shape, the rest of the input members must all be bound
        // to HTML components outside the body.
        //
        // This empty implementation is only provided to quiet the
        // compiler when a structure with a ByteSteam is code-generated.
    }
}
