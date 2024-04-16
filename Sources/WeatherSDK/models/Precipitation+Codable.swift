// Code generated by smithy-swift-codegen. DO NOT EDIT!

import ClientRuntime

extension WeatherClientTypes.Precipitation: Swift.Codable {
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case baz
        case blob
        case foo
        case hail
        case mixed
        case other
        case rain
        case sdkUnknown
        case sleet
        case snow
    }

    public func encode(to encoder: Swift.Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
            case let .baz(baz):
                try container.encode(baz, forKey: .baz)
            case let .blob(blob):
                try container.encode(blob.base64EncodedString(), forKey: .blob)
            case let .foo(foo):
                try container.encode(foo, forKey: .foo)
            case let .hail(hail):
                var hailContainer = container.nestedContainer(keyedBy: ClientRuntime.Key.self, forKey: .hail)
                for (dictKey0, stringMap0) in hail {
                    try hailContainer.encode(stringMap0, forKey: ClientRuntime.Key(stringValue: dictKey0))
                }
            case let .mixed(mixed):
                try container.encode(mixed.rawValue, forKey: .mixed)
            case let .other(other):
                try container.encode(other, forKey: .other)
            case let .rain(rain):
                try container.encode(rain, forKey: .rain)
            case let .sleet(sleet):
                try container.encode(sleet, forKey: .sleet)
            case let .snow(snow):
                try container.encode(snow.rawValue, forKey: .snow)
            case let .sdkUnknown(sdkUnknown):
                try container.encode(sdkUnknown, forKey: .sdkUnknown)
        }
    }

    public init(from decoder: Swift.Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rainDecoded = try values.decodeIfPresent(Swift.Bool.self, forKey: .rain)
        if let rain = rainDecoded {
            self = .rain(rain)
            return
        }
        let sleetDecoded = try values.decodeIfPresent(Swift.Bool.self, forKey: .sleet)
        if let sleet = sleetDecoded {
            self = .sleet(sleet)
            return
        }
        let hailContainer = try values.decodeIfPresent([Swift.String: Swift.String?].self, forKey: .hail)
        var hailDecoded0: [Swift.String:Swift.String]? = nil
        if let hailContainer = hailContainer {
            hailDecoded0 = [Swift.String:Swift.String]()
            for (key0, string0) in hailContainer {
                if let string0 = string0 {
                    hailDecoded0?[key0] = string0
                }
            }
        }
        if let hail = hailDecoded0 {
            self = .hail(hail)
            return
        }
        let snowDecoded = try values.decodeIfPresent(WeatherClientTypes.SimpleYesNo.self, forKey: .snow)
        if let snow = snowDecoded {
            self = .snow(snow)
            return
        }
        let mixedDecoded = try values.decodeIfPresent(WeatherClientTypes.TypedYesNo.self, forKey: .mixed)
        if let mixed = mixedDecoded {
            self = .mixed(mixed)
            return
        }
        let otherDecoded = try values.decodeIfPresent(WeatherClientTypes.OtherStructure.self, forKey: .other)
        if let other = otherDecoded {
            self = .other(other)
            return
        }
        let blobDecoded = try values.decodeIfPresent(ClientRuntime.Data.self, forKey: .blob)
        if let blob = blobDecoded {
            self = .blob(blob)
            return
        }
        let fooDecoded = try values.decodeIfPresent(WeatherClientTypes.Foo.self, forKey: .foo)
        if let foo = fooDecoded {
            self = .foo(foo)
            return
        }
        let bazDecoded = try values.decodeIfPresent(WeatherClientTypes.Baz.self, forKey: .baz)
        if let baz = bazDecoded {
            self = .baz(baz)
            return
        }
        self = .sdkUnknown("")
    }
}
