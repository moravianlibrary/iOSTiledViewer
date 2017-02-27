//
//  ITVBackgroundView.swift
//  Pods
//
//  Created by Jakub Fiser on 22/12/2016.
//
//

import UIKit

class ITVBackgroundView: UIView {

    internal var image: ITVImageDescriptor! {
        didSet {
            if image == nil {
                clearCache()
                refreshLayout()
            } else {
                let l = layer as! CATiledLayer
                if let size = try? image.tileSize[level] {
                    l.tileSize = size
                }
                l.levelsOfDetail = image.zoomScales.count
                
                // must be on main thread
                self.setNeedsLayout()
            }
        }
    }
    
    //    fileprivate let urlSession = URLSession(configuration: .default)
    fileprivate var imageCache = [String:UIImage]()
    fileprivate var lastLevel: Int = -1
    fileprivate var level: Int {
        get {
            return Int(round(log2(contentScaleFactor)))
        }
    }
    override var contentScaleFactor: CGFloat {
        didSet {
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
    
    /**
     Method searches cache by level for existing records. Once an record for level is found, that level is set as a background level to display.
     */
    func setScaleFor(level: Int) {
        var lvl = level - 1
        
        let allKeys = imageCache.keys.joined(separator: ",")
        let allKeysRange = NSRange(location: 0, length: allKeys.characters.count)
        while lvl > 0 {
            if let regex = try? NSRegularExpression(pattern: "\(lvl)-[0-9]+-[0-9]+"),
                regex.numberOfMatches(in: allKeys, range: allKeysRange) > 0 {
                break
            }
            
            lvl -= 1
        }
        
        if lvl < 1 {
            contentScaleFactor = 1.0
        } else {
            contentScaleFactor = pow(2.0, CGFloat(lvl))
        }
    }
    
    func addToCache(dict: [String: UIImage]) {
        for (key, value) in dict {
            imageCache[key] = value
        }
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
        
        let displayTileBorders = false
        
        let cacheKey = "\(level)-\(column)-\(row)"
        if let image = imageCache[cacheKey] {
            image.draw(in: rect)
        }
        
        if displayTileBorders {
            UIColor.green.set()
            context.setLineWidth(1)
            context.stroke(rect)
        }
    }
}
