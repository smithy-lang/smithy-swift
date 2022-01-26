//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	

import AwsCommonRuntimeKit

public class ClientRuntime {
    /**
     Initializes the underlying runtime.  You will need to do call prior to using the functions that call
     into lower level interfaces... TODO.. FINISH
     directly (instead of a higher level SDK).

     - Note: It is expected that calling this function is idempotent. Do your best to call
     this function once and only once, but it should be safe to call this multiple times during
     start up
     */
    static func initialize() {
        AwsCommonRuntimeKit.initialize()
    }

    /**
    TODO:

     - Note: It is expected that calling this function is idempotent. Do your best to call
     this function once and only once, but it should be safe to call this multiple times during
     start up
     */
    static func cleanUp() {
        AwsCommonRuntimeKit.cleanUp()
    }
}
