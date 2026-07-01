//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Smithy
@_spi(SchemaBasedSerde) import struct Smithy.DefaultTrait
@_spi(SchemaBasedSerde) @testable import SmithyCodegenCore

class SmithyCodegenCoreTests: XCTestCase {

    // This test runs against the real model for smithy-rpcv2-cbor protocol tests,
    // which is embedded in this test bundle as a resource.
    //
    // When the code generator runs as part of the build system,
    // the debugger does not attach and the only indication you have of what went wrong
    // is the error message that gets written to the build logs.
    //
    // Running the code generator from here allows the debugger to attach so that you
    // can debug a code generation step that is failing during builds.
    func test_generates_rpcv2_cbor_protocol() throws {
        let tempDirURL = FileManager.default.temporaryDirectory
        let settings = try SwiftSettings(
            service: "smithy.protocoltests.rpcv2Cbor#RpcV2Protocol",
            sdkId: "RpcV2Protocol"
        )
        let generator = try CodeGenerator(
            settings: settings,
            modelFileURL: Bundle.module.url(forResource: "smithy-rpcv2-cbor", withExtension: "json")!,
            schemasFileURL: tempDirURL.appendingPathComponent("Schemas.swift"),
            serializeFileURL: tempDirURL.appendingPathComponent("Serialize.swift"),
            deserializeFileURL: tempDirURL.appendingPathComponent("Deserialize.swift"),
            typeRegistryFileURL: tempDirURL.appendingPathComponent("TypeRegistry.swift"),
            operationsFileURL: tempDirURL.appendingPathComponent("Operations.swift")
        )
        try generator.run()
    }

    // A trait type registered under a Shape ID that is already used by a builtin trait type
    // must cause model creation to throw, rather than silently colliding or trapping.
    func test_init_throwsWhenAdditionalTraitTypeDuplicatesABuiltinTraitID() throws {
        let astModel = try Self.emptyASTModel()
        XCTAssertThrowsError(
            // DefaultTrait is already a builtin runtime trait, so re-registering it is a duplicate.
            try Model(astModel: astModel, additionalTraitTypes: [DefaultTrait.self])
        ) { error in
            XCTAssertTrue(error is ModelError)
        }
    }

    // Registering only the builtin trait types (no additions) is not a duplicate and must succeed.
    func test_init_succeedsWithNoAdditionalTraitTypes() throws {
        let astModel = try Self.emptyASTModel()
        XCTAssertNoThrow(try Model(astModel: astModel, additionalTraitTypes: []))
    }

    private static func emptyASTModel() throws -> ASTModel {
        let json = Data(#"{ "smithy": "2.0", "shapes": {} }"#.utf8)
        return try JSONDecoder().decode(ASTModel.self, from: json)
    }
}
