//
//  ITVTiledView.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

import UIKit
import SDWebImage

class ITVTiledView: UIView {

    internal var image: ITVImageDescriptor! {
        didSet {
            backgroundView?.image = image
            
            if image == nil {
                invalidateSession()
                clearCache()
                refreshLayout()
            } else {
                let l = layer as! CATiledLayer
                if case 0..<image.tileSize.count = level {
                    l.tileSize = image.tileSize[level]
                }
                // must be on main thread
                self.setNeedsLayout()
            }
        }
    }
    
    internal var backgroundView: ITVBackgroundView?
    
    fileprivate var session = URLSession(configuration: .default)
    internal var itvDelegate: ITVScrollViewDelegate?
    fileprivate var imageCache = [String:UIImage]()
    fileprivate var lastLevel: Int = -1
    fileprivate var level: Int {
        get {
            return Int(round(log2(contentScaleFactor)))
        }
    }
    override var contentScaleFactor: CGFloat {
        didSet {
            // pass cache with new images to background tiled view
            backgroundView?.addToCache(dict: imageCache)
            backgroundView?.setScaleFor(level: level)
            
            // reset cache of CATiledLayer
            refreshLayout()
        }
    }
    
    /// use specific subclass of CALayer, that allows tile based image rendering
    override class var layerClass: AnyClass {
        return CATiledLayer.self
    }
    
    init() {
        super.init(frame: CGRect.zero)
        
        // provide transparent background for easy customization in storyboard
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func clearCache() {
        imageCache.removeAll()
    }
    
    func refreshLayout() {
        layer.contents = nil
        layer.setNeedsDisplay()
    }
    
    fileprivate func invalidateSession() {
        session.invalidateAndCancel()
        session = URLSession(configuration: .default)
    }
    
    override func draw(_ rect: CGRect) {
        guard image != nil, let _ = UIGraphicsGetCurrentContext(), !rect.isInfinite, !rect.isNull else {
            return
        }

        var viewScale: CGFloat = 0
        var tiledLayer: CATiledLayer!
        var level = 0
        DispatchQueue.main.sync {
            viewScale = self.contentScaleFactor
            tiledLayer = self.layer as! CATiledLayer
            level = self.level
        }

        let tileSize = tiledLayer.tileSize
        
        let column = Int(rect.midX * viewScale / tileSize.width)
        let row = Int(rect.midY * viewScale / tileSize.height)
        
        let cacheKey = "\(level)-\(column)-\(row)"
        if let image = imageCache[cacheKey] {
            image.draw(in: rect)
        } else if let requestURL = image.getUrl(x: column, y: row, level: level) {
            session.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                if (error as NSError?)?.code == NSURLErrorCancelled {
                    // task was cancelled
                    return
                } else if data != nil {
                    if let img = UIImage.sd_image(with: data) {
                        self.imageCache[cacheKey] = img
                        DispatchQueue.main.async {
                            self.setNeedsDisplay(rect)
                        }
                    } else {
                        let error = NSError.create(ITVError.imageDecoding, "Error decoding data from \(requestURL.absoluteString).")
                        self.itvDelegate?.errorDidOccur(error: error)
                    }
                } else {
                    var errorCode = ""
                    if let code = (response as? HTTPURLResponse)?.statusCode {
                        errorCode = "\(code) "
                    }
                    let error = NSError.create(ITVError.imageDownloading, "Error " + errorCode + "while downloading data from \(requestURL.absoluteString).")
                    self.itvDelegate?.errorDidOccur(error: error)
                }
            }).resume()
        } else if !(image is RawImageDescriptor) {
            // probably out of image's bounds
            print("Request for non-existing tile at \(level):[\(column),\(row)].")
        }
    }
}
