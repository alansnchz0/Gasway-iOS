//
//  ArtworkViews.swift
//  Gasway
//
//  Created by Alan Sánchez Vázquez on 3/7/18.
//  Copyright © 2018 alansnchz. All rights reserved.
//

import Foundation
import MapKit

class ArtworkMarkerView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            guard let artwork = newValue as? Artwork else { return }
            canShowCallout = true
            calloutOffset = CGPoint(x: 0, y: 0)
            rightCalloutAccessoryView = UIButton(type: .detailDisclosure)

            markerTintColor = artwork.markerTintColor
            glyphText = artwork.gylphText
        }
    }
}
