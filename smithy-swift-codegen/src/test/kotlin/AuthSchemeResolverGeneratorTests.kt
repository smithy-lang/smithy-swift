/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class AuthSchemeResolverGeneratorTests {
    @Test
    fun `test auth scheme resolver generation`() {
        val context = setupTests("auth-scheme-resolver-generator-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/Example/AuthSchemeResolver.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce(
            """
public struct ExampleAuthSchemeResolverParameters: SmithyHTTPAuthAPI.AuthSchemeResolverParameters {
    public let operation: Swift.String
    // Region is used for SigV4 auth scheme
    public let region: Swift.String?
}

public protocol ExampleAuthSchemeResolver: SmithyHTTPAuthAPI.AuthSchemeResolver {
    // Intentionally empty.
    // This is the parent protocol that all auth scheme resolver implementations of
    // the service Example must conform to.
}

public struct DefaultExampleAuthSchemeResolver: ExampleAuthSchemeResolver {

    public func resolveAuthScheme(params: SmithyHTTPAuthAPI.AuthSchemeResolverParameters) throws -> [SmithyHTTPAuthAPI.AuthOption] {
        var validAuthOptions = [SmithyHTTPAuthAPI.AuthOption]()
        guard let serviceParams = params as? ExampleAuthSchemeResolverParameters else {
            throw Smithy.ClientError.authError("Service specific auth scheme parameters type must be passed to auth scheme resolver.")
        }
        switch serviceParams.operation {
            case "onlyHttpApiKeyAuth":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpApiKeyAuth"))
            case "onlyHttpApiKeyAuthOptional":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpApiKeyAuth"))
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "onlyHttpBearerAuth":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpBearerAuth"))
            case "onlyHttpBearerAuthOptional":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpBearerAuth"))
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "onlyHttpApiKeyAndBearerAuth":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpApiKeyAuth"))
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpBearerAuth"))
            case "onlyHttpApiKeyAndBearerAuthReversed":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpBearerAuth"))
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpApiKeyAuth"))
            case "onlySigv4Auth":
                var sigV4Option = SmithyHTTPAuthAPI.AuthOption(schemeID: "aws.auth#sigv4")
                sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingName, value: "weather")
                guard let region = serviceParams.region else {
                    throw Smithy.ClientError.authError("Missing region in auth scheme parameters for SigV4 auth scheme.")
                }
                sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingRegion, value: region)
                validAuthOptions.append(sigV4Option)
            case "onlySigv4AuthOptional":
                var sigV4Option = SmithyHTTPAuthAPI.AuthOption(schemeID: "aws.auth#sigv4")
                sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingName, value: "weather")
                guard let region = serviceParams.region else {
                    throw Smithy.ClientError.authError("Missing region in auth scheme parameters for SigV4 auth scheme.")
                }
                sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingRegion, value: region)
                validAuthOptions.append(sigV4Option)
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "onlyCustomAuth":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "com.test#customAuth"))
            case "onlyCustomAuthOptional":
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "com.test#customAuth"))
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            default:
                var sigV4Option = SmithyHTTPAuthAPI.AuthOption(schemeID: "aws.auth#sigv4")
                sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingName, value: "weather")
                guard let region = serviceParams.region else {
                    throw Smithy.ClientError.authError("Missing region in auth scheme parameters for SigV4 auth scheme.")
                }
                sigV4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingRegion, value: region)
                validAuthOptions.append(sigV4Option)
        }
        return validAuthOptions
    }

    public func constructParameters(context: Smithy.Context) throws -> SmithyHTTPAuthAPI.AuthSchemeResolverParameters {
        guard let opName = context.getOperation() else {
            throw Smithy.ClientError.dataNotFound("Operation name not configured in middleware context for auth scheme resolver params construction.")
        }
        let opRegion = context.getRegion()
        return ExampleAuthSchemeResolverParameters(operation: opName, region: opRegion)
    }
}
"""
        )
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPRestJsonProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "Example", "2023-11-02", "Example")
        }
        context.generator.initializeMiddleware(context.generationCtx)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
