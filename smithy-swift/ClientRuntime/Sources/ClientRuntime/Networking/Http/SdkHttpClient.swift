//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import Foundation

public class SdkHttpClient {

    let engine: HttpClientEngine

    public init(engine: HttpClientEngine?, config: HttpClientConfiguration) throws {
        if let engine = engine {
        self.engine = engine
        } else {
            //CRT is the default engine
            self.engine = try CRTClientEngine(config: config)
        }
       
    }

    public func execute(request: AsyncRequest, completion: @escaping NetworkResult) {
        engine.execute(request: request, completion: completion)
    }
    
    public func close() {
        engine.close()
    }
}
