//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Partition is not a concept in generic smithy client. However the CRT EndpointsRuleEngine still requires an empty JSON
public let partitionJSON = """
{
  "version": "1.1",
  "partitions": []
}
"""
