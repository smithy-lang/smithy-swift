//
//  StreamingProvider.swift
//
//  Created by Stone, Nicki on 5/29/20.
//  Copyright © 2020 Stone, Nicki. All rights reserved.
//

import Foundation

public class StreamingProvider: NSObject, StreamDelegate {

     public typealias StreamClosure = (StreamEvents, Stream, OutputStream?, StreamErrors?) -> Void
     var streamResponse: StreamClosure?

    public func stream(closure: @escaping StreamClosure) {
        streamResponse = closure
    }

    struct Streams {
        let input: InputStream
        let output: OutputStream
    }
    lazy var boundStreams: Streams = {
        var inputOrNil: InputStream?
        var outputOrNil: OutputStream?
        Stream.getBoundStreams(withBufferSize: 4096,
                               inputStream: &inputOrNil,
                               outputStream: &outputOrNil)
        guard let input = inputOrNil, let output = outputOrNil else {
            fatalError("On return of `getBoundStreams`, both `inputStream` and `outputStream` contain non-nil streams.")
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
        switch eventCode {
        case .endEncountered:
            self.streamResponse?(.streamEnded, aStream, nil, nil)
          //  continueRunning = false
        case .errorOccurred:
            // Close the streams and alert the user that the upload failed.
            print("error ocurred")
            aStream.close()
            self.streamResponse?(.errorOccurred, aStream, nil, StreamErrors.uploadFailed)
        case .hasSpaceAvailable:
            self.streamResponse?(.readyForData, aStream, boundStreams.output, nil)
        case .hasBytesAvailable:
            self.streamResponse?(.receivedData, aStream, nil, nil)
        case .openCompleted:
            self.streamResponse?(.openSuccessful, aStream, nil, nil)
        default:
            self.streamResponse?(.errorOccurred, aStream, nil, StreamErrors.unknown)
        }
     }
}
