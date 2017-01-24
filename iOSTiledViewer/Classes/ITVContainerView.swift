//
//  ITVContainerView.swift
//  Pods
//
//  Created by Jakub Fiser on 22/01/2017.
//
//

import UIKit

class ITVContainerView: UIView {
    
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
            tiledView
        }
    }
    
    var image: ITVImageDescriptor? {
        didSet {
            if image != nil {
                self.loadBackground(image?.getBackgroundUrl())
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
        
        tiledView.backgroundView = backTiledView
    }
    
    func clearCache() {
        tiledView.clearCache()
        backTiledView.clearCache()
    }
    
    func refreshTiles() {
        tiledView.refreshLayout()
    }
}


extension ITVContainerView {
    /**
     */
    fileprivate func loadBackground(_ backgroundUrl: URL?) {
        backgroundImage.backgroundColor = UIColor.clear
        
        guard let url = backgroundUrl else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if data != nil, let image = UIImage(data: data!) {
                DispatchQueue.main.async {
                    self.backgroundImage.image = image
                }
            }
        }.resume()
    }
}
