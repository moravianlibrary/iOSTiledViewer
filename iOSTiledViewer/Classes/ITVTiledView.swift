//
//  ITVTiledView.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

import UIKit

class ITVTiledView: UIView {

    internal var image: ITVImageDescriptor! {
        didSet {
            backgroundView?.image = image
            
            let l = layer as! CATiledLayer
            if let size = image.tileSize?[level] {
                l.tileSize = size
            }
            l.levelsOfDetail = image.zoomScales.count
            
            // must be on main thread
            self.setNeedsLayout()
        }
    }
    
    internal var backgroundView: ITVBackgroundView?
    
    fileprivate var imageCache = [String:UIImage]()
    fileprivate var lastLevel: Int = -1
    fileprivate var level: Int {
        get {
            return Int(round(log2(contentScaleFactor)))
        }
    }
    override var contentScaleFactor: CGFloat {
        didSet {
            // keep in cache only images for single level to save some memory
//            self.imageCache.removeAll()
            backgroundView?.addToCache(dict: imageCache)
            backgroundView?.setScaleFor(level: level)
            
            // reset cache of CATiledLayer
            layer.contents = nil
            layer.setNeedsDisplay()
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
    
    override func draw(_ rect: CGRect) {
        
        guard image != nil, let context = UIGraphicsGetCurrentContext(), !rect.isInfinite, !rect.isNull else {
            return
        }
        
        let viewScale = self.contentScaleFactor
        let viewSize = bounds.width * contentScaleFactor
        
        let scale = CGFloat(image.width)/viewSize
        
        let tiledLayer = self.layer as! CATiledLayer
        let tileSize = tiledLayer.tileSize
        
        let column = Int(rect.midX * viewScale / tileSize.width)
        let row = Int(rect.midY * viewScale / tileSize.height)
        let level = self.level
        
        /// TODO: make borders setting modifiable to user as well
        let displayTileBorders = false
        
        let cacheKey = "\(level)-\(column)-\(row)"
        if let image = imageCache[cacheKey] {
            image.draw(in: rect)
        }
        else if let requestURL = image.getUrl(x: column, y: row, level: level, scale: scale) {
            URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                if data != nil , let image = UIImage(data: data!) {
                    self.imageCache[cacheKey] = image
                    DispatchQueue.main.async {
                        self.setNeedsDisplay(rect)
                    }
                } else {
                    print("Error getting image from \(requestURL.absoluteString).") // nemel by se zde zavolat error delegate?
                }
            }).resume()
        }
        
        if displayTileBorders {
            UIColor.green.set()
            context.setLineWidth(1)
            context.stroke(rect)
        }
    }
}
