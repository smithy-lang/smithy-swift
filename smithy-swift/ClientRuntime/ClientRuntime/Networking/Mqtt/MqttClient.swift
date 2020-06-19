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
import Network

/*
class MqttClient {
    let connection: NWConnection
    
    init() {
        //let params = NWParameters()
        
        
        connection = NWConnection(host: "google.com", port: .init(integerLiteral: 8883), using: .tcp)
        
        connection.stateUpdateHandler = { (newState) in
            switch(newState) {
            case .ready:
                //Handle connection established
                //can read and write now to connection
                self.sendData()
                break
            case .waiting(let error):
                //waiting for network connection
                print(error)
            case .preparing:
                //weaves back and forth between preparing and waiting untl connection is established
                print("preparing")
            case .failed(let error):
                print(error)
            default:
                break
            }
            
        }
        
        connection.viabilityUpdateHandler = { (isViable) in
            
            if(!isViable) {
                //handle connection losing connnectivity
            }
            else {
                //handle return to connectivity
            }
            
        }
        
        connection.betterPathUpdateHandler = { (betterPathAvailable) in
            if (betterPathAvailable) {
                //start a new connection if migration is possible
            }
            else {
                //stop any attempts ot migrate
            }
            
        }
        connection.start(queue: DispatchQueue(label: "com.amazon.aws.mqtt"))
    }

    
    func sendData() {
        let data = "hello".data(using: .utf8)
        connection.send(content: data, completion: .contentProcessed({ (error) in
            if let error = error {
                print(error)
            }
        }))
        
        connection.receiveMessage { (content, context, isComplete, error) in
            if content != nil {
                print ("data received")
            }
        }
        
        //can also use Stream.getStreamsToHost not sure what the performance difference is or why one vs other for mqtt
       // Stream.getStreamsToHost(withName: "Mqtt", port: 8883, inputStream: InputStream(), outputStream: OutputStream())
    }
}
*/
