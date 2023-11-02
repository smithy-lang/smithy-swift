/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.aws.swift.codegen

import MockHttpRestJsonProtocolGenerator
import TestContext
import defaultSettings
import getFileContents
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import shouldSyntacticSanityCheck

class AuthSchemeResolverGeneratorTests {
    @Test
    fun `test auth scheme resolver`() {
        val context = setupTests("auth-scheme-resolver-generator-test.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/Example/AuthSchemeResolver.swift")
        contents.shouldSyntacticSanityCheck()
        contents.shouldContainOnlyOnce(
            """
                public struct ExampleAuthSchemeResolverParameters: ClientRuntime.AuthSchemeResolverParameters {
                    public let operation: String
                    // Region is used for SigV4 auth scheme
                    public let region: String?
                }

                public protocol ExampleAuthSchemeResolver: ClientRuntime.AuthSchemeResolver {
                    // Intentionally empty.
                    // This is the parent protocol that all auth scheme resolver implementations of
                    // the service Example must conform to.
                }

                public struct DefaultExampleAuthSchemeResolver: ExampleAuthSchemeResolver {
                    public func resolveAuthScheme(params: ClientRuntime.AuthSchemeResolverParameters) throws -> [AuthOption] {
                        var validAuthOptions = Array<AuthOption>()
                        guard let serviceParams = params as? ExampleAuthSchemeResolverParameters else {
                            throw ClientError.authError("Service specific auth scheme parameters type must be passed to auth scheme resolver.")
                        }
                        switch serviceParams.operation {
                            case "onlyHttpApiKeyAuth":
                                validAuthOptions.append(AuthOption(schemeID: "smithy.api#httpApiKeyAuth"))
                            case "onlyHttpApiKeyAuthOptional":
                                validAuthOptions.append(AuthOption(schemeID: "smithy.api#httpApiKeyAuth"))
                                validAuthOptions.append(AuthOption(schemeID: "smithy.api#noAuth"))
                            case "onlyHttpBearerAuth":
                                validAuthOptions.append(AuthOption(schemeID: "smithy.api#httpBearerAuth"))
                            case "onlyHttpBearerAuthOptional":
                                validAuthOptions.append(AuthOption(schemeID: "smithy.api#httpBearerAuth"))
                                validAuthOptions.append(AuthOption(schemeID: "smithy.api#noAuth"))
                            case "onlyHttpApiKeyAndBearerAuth":
                                validAuthOptions.append(AuthOption(schemeID: "smithy.api#httpApiKeyAuth"))
                                validAuthOptions.append(AuthOption(schemeID: "smithy.api#httpBearerAuth"))
                            case "onlyHttpApiKeyAndBearerAuthReversed":
                                validAuthOptions.append(AuthOption(schemeID: "smithy.api#httpBearerAuth"))
                                validAuthOptions.append(AuthOption(schemeID: "smithy.api#httpApiKeyAuth"))
                            case "onlySigv4Auth":
                                var sigV4Option = AuthOption(schemeID: "aws.auth#sigv4")
                                sigV4Option.signingProperties.set(key: AttributeKeys.signingName, value: "weather")
                                guard let region = serviceParams.region else {
                                    throw ClientError.authError("Missing region in auth scheme parameters for SigV4 auth scheme.")
                                }
                                sigV4Option.signingProperties.set(key: AttributeKeys.signingRegion, value: region)
                                sigV4Option.signingProperties.set(key: AttributeKeys.unsignedBody, value: false)
                                sigV4Option.signingProperties.set(key: AttributeKeys.signedBodyHeader, value: .none)
                                validAuthOptions.append(sigV4Option)
                            case "onlySigv4AuthOptional":
                                var sigV4Option = AuthOption(schemeID: "aws.auth#sigv4")
                                sigV4Option.signingProperties.set(key: AttributeKeys.signingName, value: "weather")
                                guard let region = serviceParams.region else {
                                    throw ClientError.authError("Missing region in auth scheme parameters for SigV4 auth scheme.")
                                }
                                sigV4Option.signingProperties.set(key: AttributeKeys.signingRegion, value: region)
                                sigV4Option.signingProperties.set(key: AttributeKeys.unsignedBody, value: false)
                                sigV4Option.signingProperties.set(key: AttributeKeys.signedBodyHeader, value: .none)
                                validAuthOptions.append(sigV4Option)
                                validAuthOptions.append(AuthOption(schemeID: "smithy.api#noAuth"))
                            case "onlyCustomAuth":
                                validAuthOptions.append(AuthOption(schemeID: "com.test#customAuth"))
                            case "onlyCustomAuthOptional":
                                validAuthOptions.append(AuthOption(schemeID: "com.test#customAuth"))
                                validAuthOptions.append(AuthOption(schemeID: "smithy.api#noAuth"))
                            default:
                                var sigV4Option = AuthOption(schemeID: "aws.auth#sigv4")
                                sigV4Option.signingProperties.set(key: AttributeKeys.signingName, value: "weather")
                                guard let region = serviceParams.region else {
                                    throw ClientError.authError("Missing region in auth scheme parameters for SigV4 auth scheme.")
                                }
                                sigV4Option.signingProperties.set(key: AttributeKeys.unsignedBody, value: false)
                                sigV4Option.signingProperties.set(key: AttributeKeys.signedBodyHeader, value: .none)
                                validAuthOptions.append(sigV4Option)
                        }
                        return validAuthOptions
                    }

                    public func constructParameters(context: HttpContext) throws -> ClientRuntime.AuthSchemeResolverParameters {
                        guard let opName = context.getOperation() else {
                            throw ClientError.dataNotFound("Operation name not configured in middleware context for auth scheme resolver params construction.")
                        }
                        let opRegion = context.getRegion()
                        return ExampleAuthSchemeResolverParameters(operation: opName, region: opRegion)
                    }
                }
            """.trimIndent()
        )
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHttpRestJsonProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "Example", "2023-11-02", "Example")
        }
        context.generator.initializeMiddleware(context.generationCtx)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateSerializers(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}
