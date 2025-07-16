package software.amazon.smithy.swift.codegen.requestandresponse.requestflow

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.TestContext
import software.amazon.smithy.swift.codegen.defaultSettings
import software.amazon.smithy.swift.codegen.getFileContents
import software.amazon.smithy.swift.codegen.protocolgeneratormocks.MockHTTPRestJsonProtocolGenerator
import software.amazon.smithy.swift.codegen.shouldSyntacticSanityCheck

class AuthSchemeResolverGeneratorTests {
    @Test
    fun `test auth scheme resolver generation`() {
        val context = setupTests("auth-scheme-resolver-generator-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "Sources/Example/AuthSchemeResolver.swift")
        contents.shouldSyntacticSanityCheck()
        val expected = """
public struct ExampleAuthSchemeResolverParameters: SmithyHTTPAuthAPI.AuthSchemeResolverParameters {
    public let authSchemePreference: [String]?
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
                var httpApiKeyAuthOption = SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpApiKeyAuth")
                validAuthOptions.append(httpApiKeyAuthOption)
            case "onlyHttpApiKeyAuthOptional":
                var httpApiKeyAuthOption = SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpApiKeyAuth")
                validAuthOptions.append(httpApiKeyAuthOption)
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "onlyHttpBearerAuth":
                var httpBearerAuthOption = SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpBearerAuth")
                validAuthOptions.append(httpBearerAuthOption)
            case "onlyHttpBearerAuthOptional":
                var httpBearerAuthOption = SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpBearerAuth")
                validAuthOptions.append(httpBearerAuthOption)
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "onlyHttpApiKeyAndBearerAuth":
                var httpApiKeyAuthOption = SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpApiKeyAuth")
                validAuthOptions.append(httpApiKeyAuthOption)
                var httpBearerAuthOption = SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpBearerAuth")
                validAuthOptions.append(httpBearerAuthOption)
            case "onlyHttpApiKeyAndBearerAuthReversed":
                var httpBearerAuthOption = SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpBearerAuth")
                validAuthOptions.append(httpBearerAuthOption)
                var httpApiKeyAuthOption = SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#httpApiKeyAuth")
                validAuthOptions.append(httpApiKeyAuthOption)
            case "onlySigv4Auth":
                var sigv4Option = SmithyHTTPAuthAPI.AuthOption(schemeID: "aws.auth#sigv4")
                sigv4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingName, value: "weather")
                guard let region = serviceParams.region else {
                    throw Smithy.ClientError.authError("Missing region in auth scheme parameters for SigV4 auth scheme.")
                }
                sigv4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingRegion, value: region)
                validAuthOptions.append(sigv4Option)
            case "onlySigv4AuthOptional":
                var sigv4Option = SmithyHTTPAuthAPI.AuthOption(schemeID: "aws.auth#sigv4")
                sigv4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingName, value: "weather")
                guard let region = serviceParams.region else {
                    throw Smithy.ClientError.authError("Missing region in auth scheme parameters for SigV4 auth scheme.")
                }
                sigv4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingRegion, value: region)
                validAuthOptions.append(sigv4Option)
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            case "onlyCustomAuth":
                var customAuthOption = SmithyHTTPAuthAPI.AuthOption(schemeID: "com.test#customAuth")
                validAuthOptions.append(customAuthOption)
            case "onlyCustomAuthOptional":
                var customAuthOption = SmithyHTTPAuthAPI.AuthOption(schemeID: "com.test#customAuth")
                validAuthOptions.append(customAuthOption)
                validAuthOptions.append(SmithyHTTPAuthAPI.AuthOption(schemeID: "smithy.api#noAuth"))
            default:
                var sigv4Option = SmithyHTTPAuthAPI.AuthOption(schemeID: "aws.auth#sigv4")
                sigv4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingName, value: "weather")
                guard let region = serviceParams.region else {
                    throw Smithy.ClientError.authError("Missing region in auth scheme parameters for SigV4 auth scheme.")
                }
                sigv4Option.signingProperties.set(key: SmithyHTTPAuthAPI.SigningPropertyKeys.signingRegion, value: region)
                validAuthOptions.append(sigv4Option)
        }
        return self.reprioritizeAuthOptions(authSchemePreference: serviceParams.authSchemePreference, authOptions: validAuthOptions)
    }

    public func constructParameters(context: Smithy.Context) throws -> SmithyHTTPAuthAPI.AuthSchemeResolverParameters {
        guard let opName = context.getOperation() else {
            throw Smithy.ClientError.dataNotFound("Operation name not configured in middleware context for auth scheme resolver params construction.")
        }
        let authSchemePreference = context.getAuthSchemePreference()
        let opRegion = context.getRegion()
        return ExampleAuthSchemeResolverParameters(authSchemePreference: authSchemePreference, operation: opName, region: opRegion)
    }
}
"""
        contents.shouldContainOnlyOnce(expected)
    }

    private fun setupTests(
        smithyFile: String,
        serviceShapeId: String,
    ): TestContext {
        val context =
            TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPRestJsonProtocolGenerator()) { model ->
                model.defaultSettings(serviceShapeId, "Example", "2023-11-02", "Example")
            }
        context.generator.initializeMiddleware(context.generationCtx)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
