//
//  ViewController.swift
//  NetworkEducation
//
//  Created by Данил on 04.02.2022.
//

import AVFoundation
import AVKit
import UIKit

class ViewController: UIViewController {

    // Сюда сохраняется песни
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let downloadService = DownloadService()
    let queryService = QueryService()
    
    let cellID = "ItunesCell"
    
    var searchResults: [Track] = []
    
    lazy var tapRecognizer: UITapGestureRecognizer = {
      var recognizer = UITapGestureRecognizer(target:self, action: #selector(dismissKeyboard))
      return recognizer
    }()
    
    lazy var downloadsSession: URLSession = {
      let configuration = URLSessionConfiguration.default
      return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    //MARK: logic
    @objc func dismissKeyboard() {
      searchBar.resignFirstResponder()
    }
    
    func localFilePath(for url: URL) -> URL {
      return documentsPath.appendingPathComponent(url.lastPathComponent)
    }
    
    func playDownload(_ track: Track) {
      let playerViewController = AVPlayerViewController()
      present(playerViewController, animated: true, completion: nil)
      
      let url = localFilePath(for: track.previewURL)
      let player = AVPlayer(url: url)
      playerViewController.player = player
      player.play()
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
      return .topAttached
    }
    
    func reload(_ row: Int) {
      tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
    }
    
    
    //MARK: Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableViewAndSearch()
        searchBar.delegate = self
        // Задаем сессию
        downloadService.downloadsSession = downloadsSession
    }

    // MARK: Setup interface
    
    private func setupTableViewAndSearch() {
        view.addSubview(searchBar)
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ItunesTableViewCell.self, forCellReuseIdentifier: cellID)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    //MARK: UI elements
    
    let tableView : UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
}

// MARK: Data source and delegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! ItunesTableViewCell
        cell.delegate = self
        let track = searchResults[indexPath.row]
        // TODO 13
        cell.configure(track: track, downloaded: track.downloaded, download: downloadService.activeDownloads[track.previewURL])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 62
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let track = searchResults[indexPath.row]
        
        if track.downloaded {
          playDownload(track)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
//MARK: UISearchBarDelegate
extension ViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
    
    guard let searchText = searchBar.text, !searchText.isEmpty else {
        return
    }
    
    queryService.getSearchResults(searchTerm: searchText) { [weak self] results, errorMessage in
        if let results = results {
            self?.searchResults = results
            self?.tableView.reloadData()
            self?.tableView.setContentOffset(CGPoint.zero, animated: false)
        }
      
        if !errorMessage.isEmpty {
            print("Search error: " + errorMessage)
        }
    }
    }
  
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        view.addGestureRecognizer(tapRecognizer)
    }
  
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        view.removeGestureRecognizer(tapRecognizer)
    }
}


//MARK: ItunesTableViewCellDelegate
extension ViewController: ItunesTableViewCellDelegate {
    func cancelTapped(_ cell: ItunesTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let track = searchResults[indexPath.row]
            downloadService.cancelDownload(track)
            reload(indexPath.row)
        }
    }
    
    func downloadTapped(_ cell: ItunesTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let track = searchResults[indexPath.row]
            downloadService.startDownload(track)
            reload(indexPath.row)
        }
    }
    
    func pauseTapped(_ cell: ItunesTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let track = searchResults[indexPath.row]
            downloadService.pauseDownload(track)
            reload(indexPath.row)
        }
    }
    
    func resumeTapped(_ cell: ItunesTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let track = searchResults[indexPath.row]
            downloadService.resumeDownload(track)
            reload(indexPath.row)
        }
    }
}

//MARK: DOWNLOAD TASK
extension ViewController: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.originalRequest?.url,
              let download = downloadService.activeDownloads[url]
        else {return}
        
        download.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        // Приводит байты в удобный формат
        let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file)
        DispatchQueue.main.async {
            if let cell = self.tableView.cellForRow(at: IndexPath(row: download.track.index, section: 0)) as? ItunesTableViewCell {
                cell.updateDisplay(progress: download.progress, totalSize: totalSize)
            }
        }
        
        
        
    }
    
    // Сохранение скачанной песни
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard let sourceURL = downloadTask.originalRequest?.url else {
          return
        }
        let download = downloadService.activeDownloads[sourceURL]
        downloadService.activeDownloads[sourceURL] = nil
        // метод localFilePath генерирует постоянный файл для переданного пути, использую только имя и расширение файла
        let destinationURL = localFilePath(for: sourceURL)
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: destinationURL)
        do {
          try fileManager.copyItem(at: location, to: destinationURL)
          download?.track.downloaded = true
        } catch let error {
          print("Could not copy file to disk: \(error.localizedDescription)")
        }
        // 4
        if let index = download?.track.index {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        }
    }
}
