// Code generated by smithy-swift-codegen. DO NOT EDIT!

import ClientRuntime

struct GetForecastOutputBody: Swift.Equatable {
    let chanceOfRain: Swift.Float?
    let precipitation: WeatherClientTypes.Precipitation?
}

extension GetForecastOutputBody: Swift.Decodable {
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case chanceOfRain
        case precipitation
    }

    public init(from decoder: Swift.Decoder) throws {
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let chanceOfRainDecoded = try containerValues.decodeIfPresent(Swift.Float.self, forKey: .chanceOfRain)
        chanceOfRain = chanceOfRainDecoded
        let precipitationDecoded = try containerValues.decodeIfPresent(WeatherClientTypes.Precipitation.self, forKey: .precipitation)
        precipitation = precipitationDecoded
    }
}