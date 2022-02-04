//
//  Track.swift
//  NetworkEducation
//
//  Created by Данил on 04.02.2022.
//

import Foundation

class Track: Codable {
    
  // MARK: - Properties
  let artist: String
  let index: Int
  let name: String
  let previewURL: URL
  
  var downloaded = false
  
  init(name: String, artist: String, previewURL: URL, index: Int) {
    self.name = name
    self.artist = artist
    self.previewURL = previewURL
    self.index = index
  }
}
