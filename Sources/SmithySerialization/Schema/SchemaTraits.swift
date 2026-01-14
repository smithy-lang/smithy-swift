//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The trait IDs that should be copied into schemas.  Other traits are omitted for brevity.
///
/// This list can be expanded as features are added to Smithy/SDK that use them.
public let permittedTraitIDs: Set<String> = [
    "aws.api#service",
    "aws.protocols#awsQueryCompatible",
    "aws.protocols#awsQueryError",
    "smithy.api#sparse",
    "smithy.api#input",
    "smithy.api#output",
    "smithy.api#error",
    "smithy.api#enumValue",
    "smithy.api#jsonName",
    "smithy.api#required",
    "smithy.api#default",
    "smithy.api#timestampFormat",
    "smithy.api#sensitive",
]
