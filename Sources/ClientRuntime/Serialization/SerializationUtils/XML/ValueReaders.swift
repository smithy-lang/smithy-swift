//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyXML.Reader

extension Reader {

    public func read() throws -> ByteStream? {
        // This deserialization will never be performed in practice, since
        // a ByteStream will never be a part of
        // a XML body - if there is a streaming member in a restXml
        // output shape, the rest of the input members must all be bound
        // to HTML components outside the body.
        //
        // This empty implementation is only provided to quiet the
        // compiler when a structure with a ByteSteam is code-generated.
        return nil
    }
}
