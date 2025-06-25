//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.ContextBuilder

extension ContextBuilder {

    public func withSmithyDefaultConfig<Config: DefaultClientConfiguration & DefaultHttpClientConfiguration>(
        _ config: Config
    ) -> Smithy.ContextBuilder {
        return self
            .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
            .withLogger(value: config.logger)
            .withPartitionID(value: config.partitionID)
            .withAuthSchemes(value: config.authSchemes ?? [])
            .withAuthSchemePreference(value: config.authSchemePreference)
            .withAuthSchemeResolver(value: config.authSchemeResolver)
            .withSocketTimeout(value: config.httpClientConfiguration.socketTimeout)
            .withIdentityResolver(value: config.bearerTokenIdentityResolver, schemeID: "smithy.api#httpBearerAuth")
            .withIdentityResolver(value: config.awsCredentialIdentityResolver, schemeID: "aws.auth#sigv4")
    }
}
