//
//  QueryService.swift
//  NetworkEducation
//
//  Created by Данил on 04.02.2022.
//

import Foundation
//MARK: Подгрузка песен в поиске
class QueryService {
    var errorMessage = ""
    var tracks: [Track] = []
  
    typealias JSONDictionary = [String: Any]
    typealias QueryResult = ([Track]?, String) -> Void
    // Create default session
    let defaultSession = URLSession(configuration: .default)
    // dataTask for get request, we re-creare it each time when user perform a search
    var dataTask: URLSessionDataTask?
    
    func getSearchResults(searchTerm: String, completion: @escaping QueryResult) {
        // Отменяем предыдущее задание
        dataTask?.cancel()
        // Чтобы задать параметры в запросе используем  URLComponents
        if var urlComponents = URLComponents(string: "https://itunes.apple.com/search") {
            urlComponents.query = "media=music&entity=song&term=\(searchTerm)"
            guard let url = urlComponents.url else {return}
            print(url)
            dataTask = defaultSession.dataTask(with: url) {[weak self] data, response, error in
                defer {
                    // чтобы не было strong cycle
                      self?.dataTask = nil
                }
                if let error = error {
                    self?.errorMessage += "DataTask error: " + error.localizedDescription + "\n"
                } else if
                    let data = data,
                    let response = response as? HTTPURLResponse,
                    // code 200 - запрос выполнен успешно
                    response.statusCode == 200 {
                    self?.updateSearchResults(data)
                    DispatchQueue.main.async {
                        completion(self?.tracks, self?.errorMessage ?? "")
                    }
                }
            }
        }
        dataTask?.resume()
    }
    
    private func updateSearchResults(_ data: Data) {
        var response: JSONDictionary?
        tracks.removeAll()

        do {
            response = try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary
        } catch let parseError as NSError {
            errorMessage += "JSONSerialization error: \(parseError.localizedDescription)\n"
            return
        }

        guard let array = response!["results"] as? [Any] else {
            errorMessage += "Dictionary does not contain results key\n"
            return
        }
        var index = 0
        // Парсим JSON можно через JSONDecoder
        for trackDictionary in array {
            if let trackDictionary = trackDictionary as? JSONDictionary,
               let previewURLString = trackDictionary["previewUrl"] as? String,
               let previewURL = URL(string: previewURLString),
               let name = trackDictionary["trackName"] as? String,
               let artist = trackDictionary["artistName"] as? String {
                    tracks.append(Track(name: name, artist: artist, previewURL: previewURL, index: index))
                    index += 1
            } else {
                errorMessage += "Problem parsing trackDictionary\n"
            }
        }
    }
}
