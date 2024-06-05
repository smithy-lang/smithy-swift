//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyIdentity.CRTAWSCredentialIdentity
import enum SmithyHTTPAuthAPI.SigningAlgorithm
import enum SmithyHTTPAuthAPI.AWSSignedBodyHeader
import enum SmithyHTTPAuthAPI.AWSSignedBodyValue
import enum SmithyHTTPAuthAPI.AWSSignatureType
import protocol SmithyIdentity.AWSCredentialIdentityResolver
import struct Foundation.Date
import struct Foundation.Locale
import struct Foundation.TimeInterval
import struct SmithyHTTPAuthAPI.SigningFlags
import struct SmithyIdentity.AWSCredentialIdentity

public struct AWSSigningConfig {
    public let credentials: AWSCredentialIdentity?
    public let awsCredentialIdentityResolver: (any AWSCredentialIdentityResolver)?
    public let expiration: TimeInterval
    public let signedBodyHeader: AWSSignedBodyHeader
    public let signedBodyValue: AWSSignedBodyValue
    public let flags: SigningFlags
    public let date: Date
    public let service: String
    public let region: String
    public let shouldSignHeader: ((String) -> Bool)?
    public let signatureType: AWSSignatureType
    public let signingAlgorithm: SigningAlgorithm

    public init(
        credentials: AWSCredentialIdentity? = nil,
        awsCredentialIdentityResolver: (any AWSCredentialIdentityResolver)? = nil,
        expiration: TimeInterval = 0,
        signedBodyHeader: AWSSignedBodyHeader = .none,
        signedBodyValue: AWSSignedBodyValue,
        flags: SigningFlags,
        date: Date,
        service: String,
        region: String,
        shouldSignHeader: ((String) -> Bool)? = nil,
        signatureType: AWSSignatureType,
        signingAlgorithm: SigningAlgorithm
    ) {
        self.credentials = credentials
        self.awsCredentialIdentityResolver = awsCredentialIdentityResolver
        self.expiration = expiration
        self.signedBodyHeader = signedBodyHeader
        self.signedBodyValue = signedBodyValue
        self.flags = flags
        self.date = date
        self.service = service
        self.region = region
        self.shouldSignHeader = shouldSignHeader
        self.signatureType = signatureType
        self.signingAlgorithm = signingAlgorithm
    }
}
