//
//  Location.swift
//  iMessages
//
//  Created by Gerardo Garzon on 05/09/22.
//

import Foundation
import MessageKit
import CoreLocation

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}
