//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyXML

extension Writer {

    public func write(_ value: ByteStream?) throws {
        // This is a no-op since a ByteStream will never be a part of
        // a XML body.
        //
        // This empty implementation is only provided to quiet the
        // compiler when a structure with a ByteSteam is code-generated.
    }
}
