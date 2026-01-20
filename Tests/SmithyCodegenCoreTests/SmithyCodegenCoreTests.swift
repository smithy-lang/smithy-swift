//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Smithy
@testable import SmithyCodegenCore

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
        let generator = try CodeGenerator(
            service: "smithy.protocoltests.rpcv2Cbor#RpcV2Protocol",
            modelFileURL: Bundle.module.url(forResource: "smithy-rpcv2-cbor", withExtension: "json")!,
            schemasFileURL: tempDirURL.appendingPathComponent("Schemas.swift")
        )
        try generator.run()
    }
}
