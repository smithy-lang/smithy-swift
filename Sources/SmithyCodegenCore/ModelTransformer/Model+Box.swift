//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ClientOptionalTrait
import struct Smithy.ShapeID

extension Model {

    func optionalizeStructMembers(serviceID: ShapeID) throws -> Model {
        guard affectedServices.contains(serviceID.absoluteID) else { return self }

        let newShapes = try self.shapes.mapValues { shape in
            guard let member = shape as? MemberShape else { return shape }
            guard try member.container.type == .structure else { return shape }
            return MemberShape(
                id: member.id,
                traits: member.traits.adding([ClientOptionalTrait()]),
                targetID: member.targetID
            )
        }
        return Model(version: self.version, metadata: self.metadata, shapes: newShapes)
    }
}

private var affectedServices = [
    "com.amazonaws.ec2#AmazonEC2",
    "com.amazonaws.nimble#nimble",
    "com.amazonaws.amplifybackend#AmplifyBackend",
    "com.amazonaws.apigatewaymanagementapi#ApiGatewayManagementApi",
    "com.amazonaws.apigatewayv2#ApiGatewayV2",
    "com.amazonaws.dataexchange#DataExchange",
    "com.amazonaws.greengrass#Greengrass",
    "com.amazonaws.iot1clickprojects#AWSIoT1ClickProjects",
    "com.amazonaws.kafka#Kafka",
    "com.amazonaws.macie2#Macie2",
    "com.amazonaws.mediaconnect#MediaConnect",
    "com.amazonaws.mediaconvert#MediaConvert",
    "com.amazonaws.medialive#MediaLive",
    "com.amazonaws.mediapackage#MediaPackage",
    "com.amazonaws.mediapackagevod#MediaPackageVod",
    "com.amazonaws.mediatailor#MediaTailor",
    "com.amazonaws.pinpoint#Pinpoint",
    "com.amazonaws.pinpointsmsvoice#PinpointSMSVoice",
    "com.amazonaws.serverlessapplicationrepository#ServerlessApplicationRepository",
    "com.amazonaws.mq#mq",
    "com.amazonaws.schemas#schemas",
]
