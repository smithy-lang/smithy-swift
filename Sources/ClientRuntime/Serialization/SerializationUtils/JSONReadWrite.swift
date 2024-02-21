//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyReadWrite

public class JSONWriter {
    private let encoder: any RequestEncoder
    var data = Data()

    init(encoder: any RequestEncoder) {
        self.encoder = encoder
    }

    func encode<T: Encodable>(_ value: T) throws {
        self.data = try encoder.encode(value)
    }
}

public class JSONReader {
    private let decoder: any ResponseDecoder
    private let data: Data

    init(data: Data, decoder: any ResponseDecoder) {
        self.data = data
        self.decoder = decoder
    }

    func decode<T: Decodable>() throws -> T {
        try decoder.decode(responseBody: data)
    }
}

public enum JSONReadWrite {

    public static func documentWritingClosure<T: Encodable>(
        encoder: RequestEncoder
    ) -> DocumentWritingClosure<T, JSONWriter> {
        return { value, writingClosure in
            let jsonWriter = JSONWriter(encoder: encoder)
            try writingClosure(value, jsonWriter)
            return jsonWriter.data
        }
    }

    public static func writingClosure<T: Encodable>() -> WritingClosure<T, JSONWriter> {
        return { value, writer in
            try writer.encode(value)
        }
    }

    public static func documentReadingClosure<T: Decodable>(
        decoder: ResponseDecoder
    ) -> DocumentReadingClosure<T, JSONReader> {
        return { data, readingClosure in
            let jsonReader = JSONReader(data: data, decoder: decoder)
            if let value = try readingClosure(jsonReader) {
                return value
            } else {
                throw DocumentError.requiredValueNotPresent
            }
        }
    }

    public static func readingClosure<T: Decodable>() -> ReadingClosure<T, JSONReader> {
        return { reader in
            try reader.decode()
        }
    }
}
