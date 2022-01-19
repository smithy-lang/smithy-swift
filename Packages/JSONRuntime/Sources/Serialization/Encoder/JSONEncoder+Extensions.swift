/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation
import Runtime

public typealias JSONEncoder = Foundation.JSONEncoder
extension JSONEncoder: RequestEncoder {}
