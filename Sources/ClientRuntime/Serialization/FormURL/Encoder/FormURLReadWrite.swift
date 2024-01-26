//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import typealias SmithyReadWrite.DocumentWritingClosure
import typealias SmithyReadWrite.WritingClosure

public class FormURLWriter {
    private let encoder: any RequestEncoder
    var data = Data()

    init(encoder: any RequestEncoder) {
        self.encoder = encoder
    }

    func encode<T: Encodable>(_ value: T) throws {
        self.data = try encoder.encode(value)
    }
}

public enum FormURLReadWrite {

    public static func documentWritingClosure<T: Encodable>(
        encoder: RequestEncoder
    ) -> DocumentWritingClosure<T, FormURLWriter> {
        return { value, writingClosure in
            let formURLWriter = FormURLWriter(encoder: encoder)
            try writingClosure(value, formURLWriter)
            return formURLWriter.data
        }
    }

    public static func writingClosure<T: Encodable>() -> WritingClosure<T, FormURLWriter> {
        return { value, writer in
            try writer.encode(value)
        }
    }
}
