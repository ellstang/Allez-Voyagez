//  DroppablePin.swift
//  allezVoyagez
//
//  Created by 唐嘉伶 on 2018/6/10.
//  Copyright © 2018 唐嘉伶. All rights reserved.

import UIKit
import MapKit

class DroppablePin: NSObject, MKAnnotation {
  dynamic var coordinate: CLLocationCoordinate2D
  var identifier: String
  
  init(coordinate: CLLocationCoordinate2D, identifier: String) {
    self.coordinate = coordinate
    self.identifier = identifier
    super.init()
  }
}
