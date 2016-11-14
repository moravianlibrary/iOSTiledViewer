//
//  ITVTiledView.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

import UIKit

class ITVTiledView: UIView {

    fileprivate var imageCache = [String:UIImage]()
    
    internal var image: ITVImageDescriptor! {
        didSet {
            let l = layer as! CATiledLayer
            l.tileSize = image.getTileSize(level: level)
            // TODO: Get number of levels from abstract class
            if let levels = (image as? IIIFImageDescriptor)?.tiles?.scaleFactors?.count {
                l.levelsOfDetail = levels
            }
            else if let levels = (image as? ZoomifyImageDescriptor)?.depth {
                l.levelsOfDetail = levels
            }
            
            // must be on main thread
            self.setNeedsLayout()
        }
    }
    
    fileprivate var lastLevel: Int = -1
    fileprivate var level: Int {
        get {
            return Int(round(log2(contentScaleFactor)))
        }
    }
    override var contentScaleFactor: CGFloat {
        didSet {
            // keep in cache only images for single level to save some memory
            self.imageCache.removeAll()
        }
    }
    
    /// use specific subclass of CALayer, that allows tile based image rendering
    override class var layerClass: AnyClass {
        return CATiledLayer.self
    }
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        
        // provide transparent background for easy customization in storyboard
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        
        guard image != nil, let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let viewScale = self.contentScaleFactor
        let viewSize = bounds.width * contentScaleFactor
        
        let scale = CGFloat(image.width)/viewSize//.width
        
        let tiledLayer = self.layer as! CATiledLayer
        let tileSize = tiledLayer.tileSize
        
        let column = Int(rect.midX * viewScale / tileSize.width)
        let row = Int(rect.midY * viewScale / tileSize.height)
        let level = self.level
        
        var requestURL: URL!
        /// make borders setting modifiable to user as well
        let displayTileBorders = false
        
        let cacheKey = "\(level)/\(column)_\(row)"
        if let image = imageCache[cacheKey] {
            image.draw(in: rect)
        }
        else {
            requestURL = image.getUrl(x: column, y: row, level: level, scale: scale)
            URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                if data != nil , let image = UIImage(data: data!) {
                    self.imageCache[cacheKey] = image
                    DispatchQueue.main.async {
                        self.setNeedsDisplay(rect)
                    }
                }
                else {
                    print("Error getting image from \(requestURL.absoluteString).")
                }
            }).resume()
        }
        
        if displayTileBorders {
            UIColor.green.set()
            context.setLineWidth(2)
            context.stroke(rect)
        }
    }

}
