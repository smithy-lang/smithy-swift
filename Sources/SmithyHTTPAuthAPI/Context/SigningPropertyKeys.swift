//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.AttributeKey
import struct Foundation.TimeInterval

public enum SigningPropertyKeys {
    public static let signingName = AttributeKey<String>(name: "SigningName")
    public static let signingRegion = AttributeKey<String>(name: "SigningRegion")
    // Keys used to store/retrieve AWSSigningConfig fields in/from signingProperties passed to AWSSigV4Signer
    public static let bidirectionalStreaming = AttributeKey<Bool>(name: "BidirectionalStreaming")
    public static let checksum = AttributeKey<String>(name: "checksum")
    public static let clockSkew = AttributeKey<TimeInterval>(name: "ClockSkew")
    public static let expiration = AttributeKey<TimeInterval>(name: "Expiration")
    public static let isChunkedEligibleStream = AttributeKey<Bool>(name: "isChunkedEligibleStream")
    public static let omitSessionToken = AttributeKey<Bool>(name: "OmitSessionToken")
    public static let shouldNormalizeURIPath = AttributeKey<Bool>(name: "ShouldNormalizeURIPath")
    public static let signatureType = AttributeKey<AWSSignatureType>(name: "SignatureType")
    public static let signedBodyHeader = AttributeKey<AWSSignedBodyHeader>(name: "SignedBodyHeader")
    public static let signingAlgorithm = AttributeKey<SigningAlgorithm>(name: "signingAlgorithm")
    public static let unsignedBody = AttributeKey<Bool>(name: "UnsignedBody")
    public static let requestUnsignedBody = AttributeKey<Bool>(name: "RequestUnsignedBody")
    public static let useDoubleURIEncode = AttributeKey<Bool>(name: "UseDoubleURIEncode")
}
