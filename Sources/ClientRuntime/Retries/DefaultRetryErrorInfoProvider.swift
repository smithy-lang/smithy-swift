//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum AwsCommonRuntimeKit.CommonRunTimeError
import struct AwsCommonRuntimeKit.CRTError
import class Foundation.NSError
import var Foundation.NSURLErrorDomain
import struct Foundation.TimeInterval
import enum SmithyHTTPAPI.HTTPStatusCode
import struct SmithyRetriesAPI.RetryErrorInfo
import protocol SmithyRetriesAPI.RetryErrorInfoProvider
import enum SmithyRetriesAPI.RetryErrorType

public enum DefaultRetryErrorInfoProvider: RetryErrorInfoProvider, Sendable {
    /// Returns information used to determine how & if to retry an error.
    /// - Parameter error: The error to be triaged for retry info
    /// - Returns: `RetryErrorInfo` for the passed error, or `nil` if the error should not be retried.
    public static func errorInfo(for error: Error) -> RetryErrorInfo? {
        let retryableStatusCodes: [HTTPStatusCode] = [
            .internalServerError,  // 500
            .badGateway,           // 502
            .serviceUnavailable,   // 503
            .gatewayTimeout,       // 504
        ]
        if let modeledError = error as? ModeledError {
            let type = type(of: modeledError)
            guard type.isRetryable else { return nil }
            let errorType: RetryErrorType = type.isThrottling ? .throttling : type.fault.retryErrorType
            return .init(errorType: errorType, retryAfterHint: nil, isTimeout: false)
        } else if let code = (error as? HTTPError)?.httpResponse.statusCode, retryableStatusCodes.contains(code) {
            return .init(errorType: .serverError, retryAfterHint: nil, isTimeout: false)
        } else if (error as NSError).domain == NSURLErrorDomain, (error as NSError).code == -1005 {
            // Domain == "NSURLErrorDomain"
            // NSURLErrorNetworkConnectionLost =         -1005
            // "The network connection was lost."
            return .init(errorType: .transient, retryAfterHint: nil, isTimeout: false)
        } else if (error as NSError).domain == NSURLErrorDomain, (error as NSError).code == -1200 {
            // Domain == "NSURLErrorDomain"
            // NSURLErrorTimedOut =             -1200
            // Secure connection (TLS/HTTPS) failed
            return .init(errorType: .transient, retryAfterHint: nil, isTimeout: false)
        } else if (error as NSError).domain == NSURLErrorDomain, (error as NSError).code == -1001 {
            // Domain == "NSURLErrorDomain"
            // NSURLErrorTimedOut =             -1001
            // "The request timed out."
            return .init(errorType: .transient, retryAfterHint: nil, isTimeout: true)
        } else if let crtError = error as? CommonRunTimeError,
                  case .crtError(let crtErrorStruct) = crtError,
                  crtErrorStruct.code == 1051 {
            // Retries CRTError(code: 1051, message: "socket is closed.", name: "AWS_IO_SOCKET_CLOSED"))
            return .init(errorType: .transient, retryAfterHint: nil, isTimeout: false)
        } else if let crtError = error as? CommonRunTimeError,
                  case .crtError(let crtErrorStruct) = crtError,
                  crtErrorStruct.code == 1048 {
            // Retries CRTError(code: 1048, message: "socket operation timed out.", name: "AWS_IO_SOCKET_TIMEOUT"))
            return .init(errorType: .transient, retryAfterHint: nil, isTimeout: true)
        } else if let crtError = error as? CommonRunTimeError,
                  case .crtError(let crtErrorStruct) = crtError,
                  crtErrorStruct.code == 1067 {
            // Retries CRTError(code: 1067, message: "Channel shutdown due to tls negotiation timeout", name: "AWS_IO_TLS_NEGOTIATION_TIMEOUT"))
            return .init(errorType: .transient, retryAfterHint: nil, isTimeout: true)
        } else if let crtError = error as? CommonRunTimeError,
                  case .crtError(let crtErrorStruct) = crtError,
                  crtErrorStruct.code == 1029 {
            // Retries CRTError "AWS_IO_TLS_ERROR_NEGOTIATION_FAILURE"
            return .init(errorType: .transient, retryAfterHint: nil, isTimeout: false)
        } else if isTransientNIOChannelError(error) {
            // SwiftNIO connection-level errors (ioOnClosedChannel, eof, etc.)
            return .init(errorType: .transient, retryAfterHint: nil, isTimeout: false)
        } else if String(reflecting: type(of: error)).hasSuffix("SmithySerialization.ResponseDecodingError") {
            // Body deserialization failed; usually mid-flight corruption that a retry can recover from.
            return .init(errorType: .transient, retryAfterHint: nil, isTimeout: false)
        }
        return nil
    }

    /// Avoids importing NIOCore / AsyncHTTPClient by matching on the error's type name.
    /// Most NIOCore.ChannelError and AsyncHTTPClient.HTTPClientError cases are transient
    /// connection-level errors; we only exclude variants that are programmer errors.
    private static func isTransientNIOChannelError(_ error: Error) -> Bool {
        let qualifiedTypeName = String(reflecting: type(of: error))
        let isNIOChannelError = qualifiedTypeName.hasSuffix("NIOCore.ChannelError")
        let isHTTPClientError = qualifiedTypeName.contains("AsyncHTTPClient")
            && qualifiedTypeName.hasSuffix("HTTPClientError")
        guard isNIOChannelError || isHTTPClientError else { return false }
        let description = String(describing: error)
        let nonRetryableDescriptions = [
            "operationUnsupported",
            "writeMessageTooLarge",
            "writeHostUnreachable",
            "unknownLocalAddress",
            "badMulticastGroupAddressFamily",
            "badInterfaceAddressFamily",
            "illegalMulticastAddress",
            "unsupportedScheme",
            "invalidURL",
            "emptyHost",
            "missingSocketPath",
            "alreadyShutdown",
            "writeAfterRequestSent",
            "incompatibleHeaders",
            "invalidHeaderFieldNames",
            "invalidHeaderFieldValues",
            "identityCodingIncorrectlyPresent",
            "redirectLimitReached",
            "redirectCycleDetected",
            "uncleanShutdown",
        ]
        return !nonRetryableDescriptions.contains(where: { description.contains($0) })
    }
}

private extension ErrorFault {

    var retryErrorType: RetryErrorType {
        switch self {
        case .client: return .clientError
        case .server: return .serverError
        }
    }
}
