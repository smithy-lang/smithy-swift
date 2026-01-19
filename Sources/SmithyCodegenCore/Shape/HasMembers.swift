//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Protocol provided as a convenience to get members from Shapes that have them.
protocol HasMembers {
    var members: [MemberShape] { get }
}
