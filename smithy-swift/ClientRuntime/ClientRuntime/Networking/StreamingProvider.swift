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

public class StreamingProvider: NSObject, StreamDelegate {
    
    var streamResponse: ((StreamEvents, Stream, OutputStream?, StreamErrors?) -> Void)?
    
    struct Streams {
        let input: InputStream
        let output: OutputStream
    }
    lazy var boundStreams: Streams = {
        var inputOrNil: InputStream? = nil
        var outputOrNil: OutputStream? = nil
        Stream.getBoundStreams(withBufferSize: 4096,
                               inputStream: &inputOrNil,
                               outputStream: &outputOrNil)
        guard let input = inputOrNil, let output = outputOrNil else {
            fatalError("On return of `getBoundStreams`, both `inputStream` and `outputStream` will contain non-nil streams.")
        }
        // configure and open output stream
        output.delegate = self
        output.schedule(in: .current, forMode: .default)
        output.open()
        return Streams(input: input, output: output)
    }()
    
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        guard aStream == boundStreams.output else {
            return
        }
        switch (eventCode) {
        case .endEncountered:
            self.streamResponse?(.streamEnded, aStream, nil, nil)
          //  continueRunning = false
        case .errorOccurred:
            // Close the streams and alert the user that the upload failed.
            print("error ocurred")
            aStream.close()
            self.streamResponse?(.errorOccurred,aStream, nil, StreamErrors.uploadFailed)
        case .hasSpaceAvailable:
            self.streamResponse?(.readyForData,aStream, boundStreams.output, nil)
        case .hasBytesAvailable:
            self.streamResponse?(.receivedData,aStream, nil, nil)
        case .openCompleted:
            self.streamResponse?(.openSuccessful,aStream, nil, nil)
        default:
            self.streamResponse?(.errorOccurred,aStream, nil, StreamErrors.unknown)
        }
     }
}
