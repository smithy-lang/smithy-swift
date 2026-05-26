//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.ContextBuilder
import struct SmithyHTTPAuth.SigV4AuthScheme

extension ContextBuilder {

    public func withSmithyDefaultConfig<Config: DefaultClientConfiguration & DefaultHttpClientConfiguration>(
        _ config: Config
    ) -> Smithy.ContextBuilder {
        let authSchemes = if let configAuthSchemes = config.authSchemes, !configAuthSchemes.isEmpty {
            configAuthSchemes
        } else {
            [SmithyHTTPAuth.SigV4AuthScheme()]
        }
        return self
            .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
            .withLogger(value: config.logger)
            .withPartitionID(value: config.partitionID)
            .withAuthSchemes(value: authSchemes)
            .withAuthSchemePreference(value: config.authSchemePreference)
            .withAuthSchemeResolver(value: config.authSchemeResolver)
            .withSocketTimeout(value: config.httpClientConfiguration.socketTimeout)
            .withIdentityResolver(value: config.bearerTokenIdentityResolver, schemeID: "smithy.api#httpBearerAuth")
            .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4")
            .withRegion(value: config.region)
            .withSigningRegion(value: config.signingRegion)
    }
}
