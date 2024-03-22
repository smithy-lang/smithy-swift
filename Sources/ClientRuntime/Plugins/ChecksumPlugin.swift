//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public class ChecksumPlugin: Plugin {

    private var checksumAlgorithm: ChecksumAlgorithm

    public init(checksumAlgorithm: ChecksumAlgorithm) {
        self.checksumAlgorithm = checksumAlgorithm
    }

    public func configureClient(clientConfiguration: ClientConfiguration) {
        if var config = clientConfiguration as? DefaultClientConfiguration {
            config.checksumAlgorithm = self.checksumAlgorithm
        }
    }
}
