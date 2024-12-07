//
//  States.swift
//  OpenSky
//
//  Created by Emre Alpago on 5.12.2024.
//

import Foundation

struct StatesResponse: Codable {
    let time: Int
    let states: [FlightState]
}

struct FlightState: Codable {
    let icao24: String
    let callsign: String
    let originCountry: String
    let timePosition: Int
    let lastContact: Int
    let longitude: Double
    let latitude: Double
    let geoAltitude: Double
    let onGround: Bool
    let velocity: Double
    let trueTrack: Double
    let verticalRate: Double
    let sensors: String?
    let baroAltitude: Double
    let squawk: String?
    let spi: Bool
    let positionSource: Int
    let category: Int

    enum CodingKeys: String, CodingKey {
        case icao24 = "icao24"
        case callsign = "callsign"
        case originCountry = "origin_country"
        case timePosition = "time_position"
        case lastContact = "last_contact"
        case longitude = "longitude"
        case latitude = "latitude"
        case geoAltitude = "geo_altitude"
        case onGround = "on_ground"
        case velocity = "velocity"
        case trueTrack = "true_track"
        case verticalRate = "vertical_rate"
        case sensors = "sensors"
        case baroAltitude = "baro_altitude"
        case squawk = "squawk"
        case spi = "spi"
        case positionSource = "position_source"
        case category = "category"
    }
}
