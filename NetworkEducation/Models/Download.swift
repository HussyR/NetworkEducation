//
//  Download.swift
//  NetworkEducation
//
//  Created by Данил on 04.02.2022.
//

import Foundation
// Для отслеживания загрузки нескольких задач
class Download {
    var isDownloading = false
    var progress: Float = 0
    var resumeData: Data?
    var task: URLSessionDownloadTask?
    var track: Track
  
    init(track: Track) {
        self.track = track
    }
}
