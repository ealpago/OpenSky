//
//  States.swift
//  OpenSky
//
//  Created by Emre Alpago on 5.12.2024.
//

import Foundation
import MapKit

struct StatesResponse: Codable {
    let time: Int
    let states: [FlightState]
}


struct FlightState: Codable {
    let icao24: String?
    let callsign: String?
    let origin_country: String?
    let time_position: Int?
    let last_contact: Int??
    let longitude: Float?
    let latitude: Float?
    let baro_altitude: Float?
    let on_ground: Bool?
    let velocity: Float?
    let true_track: Float?
    let vertical_rate: Float?
    let sensors: [Int]?
    let geo_altitude: Float?
    let squawk: String?
    let spi: Bool?
    let position_source: Int?
    let category: Int?

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        icao24 = try? container.decode(String.self)
        callsign = try? container.decode(String.self)
        origin_country = try? container.decode(String.self)
        time_position = try? container.decode(Int.self)
        last_contact = try? container.decode(Int.self)
        longitude = try? container.decode(Float.self)
        latitude = try? container.decode(Float.self)
        baro_altitude = try? container.decode(Float.self)
        on_ground = try? container.decode(Bool.self)
        velocity = try? container.decode(Float.self)
        true_track = try? container.decode(Float.self)
        vertical_rate = try? container.decode(Float.self)
        sensors = try? container.decode([Int].self)
        geo_altitude = try? container.decode(Float.self)
        squawk = try? container.decode(String.self)
        spi = try? container.decode(Bool.self)
        position_source = try? container.decode(Int.self)
        category = try? container.decode(Int.self)
    }
}

class FlightAnnotation: NSObject, MKAnnotation {
    let flightState: FlightState
    var coordinate: CLLocationCoordinate2D {
        guard let latitude = flightState.latitude, let longitude = flightState.longitude else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        return CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
    }

    var title: String? {
        return "Flight: \(flightState.icao24 ?? "")"
    }

    var subtitle: String? {
        return "Origin: \(flightState.origin_country ?? "")"
    }

    init(flightState: FlightState) {
        self.flightState = flightState
    }
}
