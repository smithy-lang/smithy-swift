/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation
import XMLCoder

public typealias XMLEncoder = XMLCoder.XMLEncoder
extension XMLEncoder: RequestEncoder {}
