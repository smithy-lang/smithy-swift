/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

/// HTTP Statuses
///
/// - continue: Continue
/// - switchingProtocols: Switching Protocols
/// - processing: Processing
/// - ok: OK
/// - created: Created
/// - accepted: Accepted
/// - nonAuthoritativeInformation: Non-authoritative Information
/// - noContent: No Content
/// - resetContent: Reset Content
/// - partialContent: Partial Content
/// - multiStatus: Multi-Status
/// - alreadyReported: Already Reported
/// - iAmUsed: IM Used
/// - multipleChoices: Multiple Choices
/// - movedPermanently: Moved Permanently
/// - found: Found
/// - seeOther: See Other
/// - notModified: Not Modified
/// - useProxy: Use Proxy
/// - temporaryRedirect: Temporary Redirect
/// - permanentRedirect: Permanent Redirect
/// - badRequest: Bad Request
/// - unauthorized: Unauthorized
/// - paymentRequired: Payment Required
/// - forbidden: Forbidden
/// - notFound: Not Found
/// - methodNotAllowed: Method Not Allowed
/// - notAcceptable: Not Acceptable
/// - proxyAuthenticationRequired: Proxy Authentication Required
/// - requestTimeout: Request Timeout
/// - conflict: Conflict
/// - gone: Gone
/// - lengthRequired: Length Required
/// - preconditionFailed: Precondition Failed
/// - payloadTooLarge: Payload Too Large
/// - requestURITooLong: Request-URI Too Long
/// - unsupportedMediaType: Unsupported Media Type
/// - requestedRangeNotSatisfiable: Requested Range Not Satisfiable
/// - expectationFailed: Expectation Failed
/// - iAmATeapot: I'm a teapot
/// - misdirectedRequest: Misdirected Request
/// - unprocessableEntity: Unprocessable Entity
/// - locked: Locked
/// - failedDependency: Failed Dependency
/// - upgradeRequired: Upgrade Required
/// - preconditionRequired: Precondition Required
/// - tooManyRequests: Too Many Requests
/// - requestHeaderFieldsTooLarge: Request Header Fields Too Large
/// - connectionClosedWithoutResponse: Connection Closed Without Response
/// - unavailableForLegalReasons: Unavailable For Legal Reasons
/// - clientClosedRequest: Client Closed Request
/// - internalServerError: Internal Server Error
/// - notImplemented: Not Implemented
/// - badGateway: Bad Gateway
/// - serviceUnavailable: Service Unavailable
/// - gatewayTimeout: Gateway Timeout
/// - httpVersionNotSupported: HTTP Version Not Supported
/// - variantAlsoNegotiates: Variant Also Negotiates
/// - insufficientStorage: Insufficient Storage
/// - loopDetected: Loop Detected
/// - notExtended: Not Extended
/// - networkAuthenticationRequired: Network Authentication Required
/// - networkConnectTimeoutError: Network Connect Timeout Error
public enum HttpStatusCode: Int, Equatable {
    case `continue` = 100
    case switchingProtocols = 101
    case processing = 102
    case ok = 200
    case created = 201
    case accepted = 202
    case nonAuthoritativeInformation = 203
    case noContent = 204
    case resetContent = 205
    case partialContent = 206
    case multiStatus = 207
    case alreadyReported = 208
    case iAmUsed = 226
    case multipleChoices = 300
    case movedPermanently = 301
    case found = 302
    case seeOther = 303
    case notModified = 304
    case useProxy = 305
    case temporaryRedirect = 307
    case permanentRedirect = 308
    case badRequest = 400
    case unauthorized = 401
    case paymentRequired = 402
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case notAcceptable = 406
    case proxyAuthenticationRequired = 407
    case requestTimeout = 408
    case conflict = 409
    case gone = 410
    case lengthRequired = 411
    case preconditionFailed = 412
    case payloadTooLarge = 413
    case requestURITooLong = 414
    case unsupportedMediaType = 415
    case requestedRangeNotSatisfiable = 416
    case expectationFailed = 417
    case iAmATeapot = 418
    case misdirectedRequest = 421
    case unprocessableEntity = 422
    case locked = 423
    case failedDependency = 424
    case upgradeRequired = 426
    case preconditionRequired = 428
    case tooManyRequests = 429
    case requestHeaderFieldsTooLarge = 431
    case connectionClosedWithoutResponse = 444
    case unavailableForLegalReasons = 451
    case clientClosedRequest = 499
    case internalServerError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case gatewayTimeout = 504
    case httpVersionNotSupported = 505
    case variantAlsoNegotiates = 506
    case insufficientStorage = 507
    case loopDetected = 508
    case notExtended = 510
    case networkAuthenticationRequired = 511
    case networkConnectTimeoutError = 599
}

extension HttpStatusCode: CustomStringConvertible {
    public var description: String {
       
        return NSLocalizedString(
            "http_status_\(rawValue)",
            tableName: "HttpStatusEnum",
            comment: ""
        )
    }
}

extension HttpStatusCode {
    public var isRetryable: Bool {
        if (502..<505).contains(rawValue) || rawValue == 500 {
            return true
        }
        return false
    }
}
