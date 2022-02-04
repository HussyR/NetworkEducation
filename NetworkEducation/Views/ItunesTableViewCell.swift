//
//  ItunesTableViewCell.swift
//  NetworkEducation
//
//  Created by Данил on 04.02.2022.
//

import UIKit

protocol ItunesTableViewCellDelegate {
  func cancelTapped(_ cell: ItunesTableViewCell)
  func downloadTapped(_ cell: ItunesTableViewCell)
  func pauseTapped(_ cell: ItunesTableViewCell)
  func resumeTapped(_ cell: ItunesTableViewCell)
}

class ItunesTableViewCell: UITableViewCell {
    //MARK: Properties
    static let identifier = "ItunesCell"
    var delegate: ItunesTableViewCellDelegate?
    
    //MARK: Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        downloadButton.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(pauseOrResumeTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }
    
    //MARK: Button actions
    
    @objc private func cancelTapped(sender: UIButton) {
        delegate?.cancelTapped(self)
    }
    
    @objc private func downloadTapped(sender: UIButton) {
        delegate?.downloadTapped(self)
    }
    
    @objc func pauseOrResumeTapped() {
        if(pauseButton.titleLabel?.text == "Pause") {
            delegate?.pauseTapped(self)
        } else {
            delegate?.resumeTapped(self)
        }
    }
    
    //MARK: Configure cell
    
    func configure(track: Track, downloaded: Bool , download: Download?) {
        var showDownloadControls = false
        if let download = download {
            showDownloadControls = true
            let title = download.isDownloading ? "Pause" : "Resume"
            pauseButton.setTitle(title, for: .normal)
            progressLabel.text = download.isDownloading ? "Downloading..." : "Paused"
        }
        pauseButton.isHidden = !showDownloadControls
        cancelButton.isHidden = !showDownloadControls
        progressView.isHidden = !showDownloadControls
        progressLabel.isHidden = !showDownloadControls
        
        titleLabel.text = track.name
        artistLabel.text = track.artist
      
        selectionStyle = downloaded ? UITableViewCell.SelectionStyle.gray : UITableViewCell.SelectionStyle.none
        downloadButton.isHidden = downloaded || showDownloadControls
    }
    
    func updateDisplay(progress: Float, totalSize : String) {
      progressView.progress = progress
      progressLabel.text = String(format: "%.1f%% of %@", progress * 100, totalSize)
    }
    
    //MARK: SetupUI
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(artistLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -102),
            
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            artistLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            artistLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -102),
        ])
        
        contentView.addSubview(cancelButton)
        contentView.addSubview(pauseButton)
        addSubview(progressLabel)
        addSubview(progressView)
        
        NSLayoutConstraint.activate([
            cancelButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            cancelButton.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            
            pauseButton.topAnchor.constraint(equalTo: cancelButton.topAnchor),
            pauseButton.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -8)
        ])
        
        NSLayoutConstraint.activate([
            progressLabel.leadingAnchor.constraint(equalTo: pauseButton.leadingAnchor),
            progressLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9),
            
            progressView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            progressView.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: 6),
            progressView.trailingAnchor.constraint(equalTo: progressLabel.leadingAnchor, constant: -11),
            
            progressLabel.centerYAnchor.constraint(equalTo: progressView.centerYAnchor)
        ])
        contentView.addSubview(downloadButton)
        NSLayoutConstraint.activate([
            downloadButton.topAnchor.constraint(equalTo: topAnchor, constant: 9),
            downloadButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -17),
            downloadButton.leadingAnchor.constraint(equalTo: progressView.trailingAnchor, constant: 11)
        ])
    }
    
    
    //MARK: UI elements
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = "Title"
        return label
    }()
    
    let artistLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.text = "Artist"
        return label
    }()
    
    let progressView : UIProgressView = {
        let progressView = UIProgressView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    let progressLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = .gray
        label.text = "100% of 1.35MB"
        return label
    }()
    
    let downloadButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Download", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.isUserInteractionEnabled = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.titleLabel?.textAlignment = .center
        return button
    }()
    
    let cancelButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.isHidden = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return button
    }()
    
    let pauseButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Pause", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.isHidden = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return button
    }()
 
    //MARK: Others
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
