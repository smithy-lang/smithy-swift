// Code generated by smithy-swift-codegen. DO NOT EDIT!

import ClientRuntime

extension WeatherClientTypes {
    public struct CityCoordinates: Swift.Equatable {
        /// This member is required.
        public var latitude: Swift.Float?
        /// This member is required.
        public var longitude: Swift.Float?

        public init(
            latitude: Swift.Float? = nil,
            longitude: Swift.Float? = nil
        )
        {
            self.latitude = latitude
            self.longitude = longitude
        }
    }

}