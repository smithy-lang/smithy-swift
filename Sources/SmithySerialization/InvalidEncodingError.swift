//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The data being deserialized was invalid, and a response could not be parsed.
///
/// If an error of this type is received, it indicates a bug either on the server or client.  Please file a [bug ticket](https://github.com/smithy-lang/smithy-swift/issues).
public struct ResponseEncodingError {

    /// The error thrown by the deserializing implementation.
    ///
    /// The exact error returned may vary depending on the encoding in use.
    public let wrapped: any Swift.Error // this will be the underlying error thrown by the parser implementation

    public init(wrapped: any Error) {
        self.wrapped = wrapped
    }
}

extension ResponseEncodingError: Error {

    public var localizedDescription: String {
        "The data in the response could not be parsed.  More info: \(wrapped)"
    }
}
