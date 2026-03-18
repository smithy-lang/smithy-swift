//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SmithyTestUtil

class CBORComparatorTests: XCTestCase {

    func test_compare_nulls() async throws {
        let cborData1 = Data()
        let cborData2 = Data()
        XCTAssertTrue(try CBORComparator.cborData(cborData1, isEqualTo: cborData2))
    }

    func test_compare_complex() async throws {
        // cborData1 is semantically different from cborData2, but logically equivalent (reordered keys in the map)
        let cborData1 = Data([
            0xBF, // Start of outer indefinite-length map

            // Key: "defaults"
            0x68, 0x64, 0x65, 0x66, 0x61, 0x75, 0x6C, 0x74, 0x73,
            0xBF, // Start of "defaults" map

                // Key: "customString"
                0x6C, 0x63, 0x75, 0x73, 0x74, 0x6F, 0x6D, 0x53, 0x74, 0x72, 0x69, 0x6E, 0x67,
                // Indefinite-length string for "hello"
                0x7F, 0x65, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0xFF,

                // Key: "defaultString"
                0x6D, 0x64, 0x65, 0x66, 0x61, 0x75, 0x6C, 0x74,
                0x53, 0x74, 0x72, 0x69, 0x6E, 0x67,
                // Indefinite-length string for "hi"
                0x7F, 0x62, 0x68, 0x69, 0xFF,

            0xFF, // End of the "defaults" map
            0xFF  // End of indefinite-length map
        ])
        let cborData2 = Data([
            0xBF, // Start of outer indefinite-length map

            // Key: "defaults"
            0x68, 0x64, 0x65, 0x66, 0x61, 0x75, 0x6C, 0x74, 0x73,
            0xBF, // Start of "defaults" map

                // Key: "defaultString"
                0x6D, 0x64, 0x65, 0x66, 0x61, 0x75, 0x6C, 0x74,
                0x53, 0x74, 0x72, 0x69, 0x6E, 0x67,
                // Indefinite-length string for "hi"
                0x7F, 0x62, 0x68, 0x69, 0xFF,

                // Key: "customString"
                0x6C, 0x63, 0x75, 0x73, 0x74, 0x6F, 0x6D, 0x53, 0x74, 0x72, 0x69, 0x6E, 0x67,
                // Indefinite-length string for "hello"
                0x7F, 0x65, 0x68, 0x65, 0x6C, 0x6C, 0x6F, 0xFF,

            0xFF, // End of the "defaults" map
            0xFF  // End of indefinite-length map
        ])
        XCTAssertTrue(try CBORComparator.cborData(cborData1, isEqualTo: cborData2))
    }
}
