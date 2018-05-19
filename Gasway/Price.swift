//
//  Price.swift
//  Gasway
//
//  Created by Alan Sánchez Vázquez on 3/7/18.
//  Copyright © 2018 alansnchz. All rights reserved.
//

import Foundation
struct Price {
    var price: String
    var type: String
    
    enum CodingKeys: String, CodingKey {
        case price
        case type
    }
}
extension Price: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(price, forKey: .price)
        try container.encode(type, forKey: .type)
    }
}

extension Price: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        price = try values.decode(String.self, forKey: .price)
        type = try values.decode(String.self, forKey: .type)
    }
}

