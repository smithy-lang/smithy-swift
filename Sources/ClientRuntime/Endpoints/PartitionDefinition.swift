//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Partition definitions are embedded as a static resource in this project, for now.
// When Trebuchet integration is performed, partitions should be obtained from Trebuchet for every
// build instead of being loaded from a static definition.
public let partitionJSON = """
{
  "version": "1.1",
  "partitions": []
}
"""
