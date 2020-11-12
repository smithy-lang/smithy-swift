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

public class HttpResponse: HttpUrlResponse {

    public var headers: Headers
    public var content: ResponseType?
    public var statusCode: HttpStatusCode
    
    init(headers: Headers = Headers(), statusCode: HttpStatusCode = HttpStatusCode.notFound) {
        self.headers = headers
        self.statusCode = statusCode
    }

    public init(headers: Headers = Headers(), content: ResponseType?, statusCode: HttpStatusCode) {
        self.content = content
        self.statusCode = statusCode
        self.headers = headers
    }
}
