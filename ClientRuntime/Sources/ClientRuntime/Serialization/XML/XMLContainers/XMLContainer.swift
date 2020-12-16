/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

//  XMLContainer.swift
//  XMLParser

import Foundation

protocol XMLContainer {

    var isNull: Bool { get }
    var xmlString: String? { get }
}

protocol XMLSimpleContainer: XMLContainer {
    // A simple tagging protocol, for now.
}

protocol TypeErasedSharedBoxProtocol {

    func unbox() -> XMLContainer
}

protocol XMLSharedContainerProtocol: TypeErasedSharedBoxProtocol {

    associatedtype ContainerType: XMLContainer
    func unbox() -> ContainerType
}
