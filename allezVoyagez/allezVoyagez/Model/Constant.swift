//  Constant.swift
//  allezVoyagez
//
//  Created by 唐嘉伶 on 2018/6/11.
//  Copyright © 2018 唐嘉伶. All rights reserved.

import Foundation

let droppablePinId = "droppablePin"

let flickrAPIKey = "15bda8eee2b875870c9bd9e77d38267d"

var lat = ""
var long = ""
var numOfPhotoPerPage = 12


func returnFlickrURL(forAPIKey key: String , withAnnotation annotation: DroppablePin, NumberOfPhoto num: Int) -> String {
  let lat = annotation.coordinate.latitude
  let long = annotation.coordinate.longitude
  var locationAPIKey = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(flickrAPIKey)&lat=\(lat)&lon=\(long)&radius=1&radius_units=km&per_page=\(num)&format=json&nojsoncallback=1"
  
  print("locationAPIKey", locationAPIKey)
  return locationAPIKey
}
