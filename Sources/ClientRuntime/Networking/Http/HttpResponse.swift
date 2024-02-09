/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import AwsCommonRuntimeKit

public actor HttpResponse: HttpUrlResponse {

    public var headers: Headers
    public var body: ByteStream
    public var statusCode: HttpStatusCode
    private var continuation: CheckedContinuation<Void, Never>?

    public func addHeaders(additionalHeaders: Headers) {
        self.headers.addAll(headers: additionalHeaders)
    }

    public func setBody(newBody: ByteStream) {
        self.body = newBody
    }

    public func setStatusCode(newStatusCode: HttpStatusCode) {
        if self.statusCode.rawValue >= 200 { return }
        let codeBeforeUpdate = self.statusCode.rawValue
        self.statusCode = newStatusCode
        if newStatusCode.rawValue >= 200 && codeBeforeUpdate < 200 {
            // Resume when status code changes to a final value from informational code [100, 200).
            // The resume happens exactly once for all code path of this continuation.
            // Any non-HTTP error
            self.continuation?.resume()
            // Nullify continuation to safe-guard against resuming continuation > 1 times.
            self.continuation = nil
        }
    }

    public func getFinalStatusCode() async -> Int {
        guard self.statusCode.rawValue < 200 else {
            return self.statusCode.rawValue
        }
        // Wait until status code gets finalized.
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
        return self.statusCode.rawValue
    }

    public init(headers: Headers = .init(), statusCode: HttpStatusCode = .processing, body: ByteStream = .noStream) {
        self.headers = headers
        self.statusCode = statusCode
        self.body = body
    }

    public init(headers: Headers = .init(), body: ByteStream, statusCode: HttpStatusCode) {
        self.body = body
        self.statusCode = statusCode
        self.headers = headers
    }
}

extension HttpResponse {
    public var debugDescriptionWithBody: String {
        return debugDescription + "\nResponseBody: \(body.debugDescription)"
    }
    public var debugDescription: String {
        return "\nStatus Code: \(statusCode.description) \n \(headers)"
    }
}
