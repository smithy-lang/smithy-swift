//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

extension SigningConfig {

    func toChunkSigningConfig() -> SigningConfig {
        let modifiedSignatureType = SignatureType.requestChunk
        let modifiedBodyType = SignedBodyValue.empty
        return SigningConfig(
            algorithm: self.algorithm,
            signatureType: modifiedSignatureType,
            service: self.service,
            region: self.region,
            date: self.date,
            credentials: self.credentials,
            credentialsProvider: self.credentialsProvider,
            expiration: self.expiration,
            signedBodyHeader: self.signedBodyHeader,
            signedBodyValue: modifiedBodyType,
            shouldSignHeader: self.shouldSignHeader,
            useDoubleURIEncode: self.useDoubleURIEncode,
            shouldNormalizeURIPath: self.shouldNormalizeURIPath,
            omitSessionToken: self.omitSessionToken
        )
    }

    func toTrailingHeadersSigningConfig() -> SigningConfig {
        let modifiedSignatureType = SignatureType.requestTrailingHeaders
        let modifiedBodyType = SignedBodyValue.empty
        return SigningConfig(
            algorithm: self.algorithm,
            signatureType: modifiedSignatureType,
            service: self.service,
            region: self.region,
            date: self.date,
            credentials: self.credentials,
            credentialsProvider: self.credentialsProvider,
            expiration: self.expiration,
            signedBodyHeader: self.signedBodyHeader,
            signedBodyValue: modifiedBodyType,
            shouldSignHeader: self.shouldSignHeader,
            useDoubleURIEncode: self.useDoubleURIEncode,
            shouldNormalizeURIPath: self.shouldNormalizeURIPath,
            omitSessionToken: self.omitSessionToken
        )
    }

    var isUnsigned: Bool {
        return signedBodyValue == .streamingUnSignedPayloadTrailer
    }
}
