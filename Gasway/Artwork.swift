//
//  Artwork.swift
//  Gasway
//
//  Created by Alan Sánchez Vázquez on 3/7/18.
//  Copyright © 2018 alansnchz. All rights reserved.
//

import Foundation
import MapKit

class Artwork: NSObject, MKAnnotation {

    let station: Station
    let priceRange: Int
    
    init(station: Station, priceRange: Int) {
        self.station = station
        self.priceRange = priceRange
        super.init()
    }
    
    var title: String? {
        return station.name
    }
    
    var subtitle: String? {
        return station.address
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: station.latitude,
                                      longitude: station.longitude)
    }
    
    var markerTintColor: UIColor  {
        switch priceRange {
            case 0:
                return UIColor(red: 0.00, green: 0.45, blue: 0.25, alpha: 1.0)
            case 1:
                return UIColor(red: 0.11, green: 0.40, blue: 0.65, alpha: 1.0)
            case 2:
                return .red
            default:
                return UIColor(red: 0.00, green: 0.45, blue: 0.25, alpha: 1.0)
        }
    }
    
    var gylphText: String {
        return station.prices[0].price
    }
}
