/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

//  XMLValueContainer.swift
//  ClientRuntime

import Foundation

protocol XMLValueContainer: XMLSimpleContainer {
    associatedtype Unboxed

    init(_ value: Unboxed)
}
