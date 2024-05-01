// Code generated by smithy-swift-codegen. DO NOT EDIT!

import ClientRuntime

struct ListCitiesOutputBody {
    let nextToken: Swift.String?
    let items: [WeatherClientTypes.CitySummary]?
}

extension ListCitiesOutputBody: Swift.Decodable {
    enum CodingKeys: Swift.String, Swift.CodingKey {
        case items
        case nextToken
    }

    public init(from decoder: Swift.Decoder) throws {
        let containerValues = try decoder.container(keyedBy: CodingKeys.self)
        let nextTokenDecoded = try containerValues.decodeIfPresent(Swift.String.self, forKey: .nextToken)
        nextToken = nextTokenDecoded
        let itemsContainer = try containerValues.decodeIfPresent([WeatherClientTypes.CitySummary?].self, forKey: .items)
        var itemsDecoded0:[WeatherClientTypes.CitySummary]? = nil
        if let itemsContainer = itemsContainer {
            itemsDecoded0 = [WeatherClientTypes.CitySummary]()
            for structure0 in itemsContainer {
                if let structure0 = structure0 {
                    itemsDecoded0?.append(structure0)
                }
            }
        }
        items = itemsDecoded0
    }
}
