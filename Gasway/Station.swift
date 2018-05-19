//
//  Station.swift
//  Gasway
//
//  Created by Alan Sánchez Vázquez on 2/14/18.
//  Copyright © 2018 alansnchz. All rights reserved.
//

import Foundation
struct Station {
    
    var placeId: String
    var address: String
    var brand: String
    var name: String
    var category: String
    var creId: String
    var latitude: Double
    var longitude: Double
    var prices: [Price]
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case address
        case brand
        case name
        case category
        case creId = "cre_id"
        case latitude = "lat"
        case longitude = "lng"
        case prices
    }
}
extension Station: Encodable {
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(placeId, forKey: .placeId)
        try container.encode(address, forKey: .address)
        try container.encode(brand, forKey: .brand)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(creId, forKey: .creId)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(prices, forKey: .prices)
    }
}

extension Station: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        placeId = try values.decode(String.self, forKey: .placeId)
        address = try values.decode(String.self, forKey: .address)
        brand = try values.decode(String.self, forKey: .brand)
        name = try values.decode(String.self, forKey: .name)
        category = try values.decode(String.self, forKey: .category)
        creId = try values.decode(String.self, forKey: .creId)
        latitude = try values.decode(Double.self, forKey: .latitude)
        longitude = try values.decode(Double.self, forKey: .longitude)
        prices = try values.decode([Price].self, forKey: .prices)
    }
}
