/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.aws.clientrt.serde.json

import software.aws.clientrt.serde.SdkFieldDescriptor
import software.aws.clientrt.serde.SerialKind

object JsonMapSdkFieldDescriptor : SdkFieldDescriptor(SerialKind.Map())
object JsonListSdkFieldDescriptor : SdkFieldDescriptor(SerialKind.List())
object JsonStructSdkFieldDescriptor : SdkFieldDescriptor(SerialKind.Struct())
