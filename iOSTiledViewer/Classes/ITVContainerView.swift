//
//  ITVContainerView.swift
//  Pods
//
//  Created by Jakub Fiser on 22/01/2017.
//
//

import UIKit
import SDWebImage

class ITVContainerView: UIView {
    
    fileprivate var backgroundTask: URLSessionDataTask?
    fileprivate let backgroundImage = UIImageView()
    let backTiledView = ITVBackgroundView()
    let tiledView = ITVTiledView()
    
    override var frame: CGRect {
        didSet {
            backgroundImage.frame = bounds
            tiledView.frame = bounds
            backTiledView.frame = bounds
        }
    }
    
    var itvDelegate: ITVScrollViewDelegate? {
        didSet {
            tiledView.itvDelegate = itvDelegate
        }
    }
    
    var image: ITVImageDescriptor? {
        didSet {
            if image != nil {
                self.loadBackground()
                self.tiledView.image = image
            }
        }
    }
    
    func initTiledView() {
        backgroundColor = UIColor.clear
        
        // add tiled and background views
        addSubview(backgroundImage)
        addSubview(backTiledView)
        addSubview(tiledView)
        
        backgroundImage.backgroundColor = UIColor.clear
        tiledView.backgroundView = backTiledView
    }
    
    func clearCache() {
        tiledView.clearCache()
        backTiledView.clearCache()
    }
    
    func clearViews() {
        clearBackground()
        tiledView.image = nil
    }
    
    func clearBackground() {
        backgroundTask?.cancel()
        backgroundImage.image = nil
    }
    
    func refreshTiles() {
        backTiledView.refreshLayout()
        tiledView.refreshLayout()
    }
    
    func loadBackground() {
        clearBackground()
        if let url = image?.getBackgroundUrl() {
            backgroundTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if data != nil, let image = UIImage.sd_image(with: data!) {
                    DispatchQueue.main.async {
                        self.backgroundImage.image = image
                    }
                }
            }
            backgroundTask?.resume()
        }
    }
}
