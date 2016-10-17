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
    
    // IIIFImageDescriptor -> make abstract class and use that
    internal var image: IIIFImageDescriptor! {
        didSet {
            let l = layer as! CATiledLayer
            if let tileSize = image.tiles?.size {
                l.tileSize = tileSize
            }
            if let levels = image.tiles?.scaleFactors?.count {
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
//            if lastLevel != level {
//                lastLevel = level
                self.imageCache.removeAll()
//            }
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
        
        var viewSize = self.frame.size
        
        let scaleW = CGFloat(image.width)/viewSize.width
        let scaleH = CGFloat(image.height)/viewSize.height
        let scale = max(scaleW, scaleH)
        
        let tiledLayer = self.layer as! CATiledLayer
        var tileSize = tiledLayer.tileSize
        
        let column = Int(rect.midX * viewScale / tileSize.width)
        let row = Int(rect.midY * viewScale / tileSize.height)
        
        var requestURL: URL!
        let displayTileBorders = false
        
        let cacheKey = "\(level)/\(column)_\(row)"
        if let image = imageCache[cacheKey] {
            image.draw(in: rect)
        }
        else {
            requestURL = self.tiledImageView(column, y: row, level: scale)
            URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                if data != nil , let image = UIImage(data: data!) {
                    self.imageCache[cacheKey] = image
                    DispatchQueue.main.async {
                        self.setNeedsDisplay(rect)
                    }
                }
            }).resume()
        }
        
        if displayTileBorders {
            UIColor.green.set()
            context.setLineWidth(2)
            context.stroke(rect)
        }
    }
    
    func tiledImageView(_ x: Int, y: Int, level: CGFloat=1.0) -> URL! {
        
        // size of full image content
        let fullSize = CGSize(width: image.width, height: image.height)
        
        // tile size
        let tileSize = (layer as! CATiledLayer).tileSize
        
        // scale factor
        let s = level
        
        // tile coordinate (col)
        let n = CGFloat(x)
        
        // tile coordinate (row)
        let m = CGFloat(y)
        
        // Calculate region parameters /xr,yr,wr,hr/
        let xr = n * tileSize.width * s
        let yr = m * tileSize.height * s
        var wr = tileSize.width * s
        if (xr + wr > fullSize.width) {
            wr = fullSize.width - xr
        }
        var hr = tileSize.height * s
        if (yr + hr > fullSize.height) {
            hr = fullSize.height - yr
        }
        
        
        // TODO: Here we will be using IIIF/Zoomify classes
        let baseUrl = image.baseUrl
        let region = "\(Int(xr)),\(Int(yr)),\(Int(wr)),\(Int(hr))"
        let size = "\(Int(tileSize.width)),\(tileSize.height == tileSize.width ? "" : String(Int(tileSize.height)))"
        let rotation = "0"
        let quality = "default"
        let format = "jpg"
        
//        print("USED ALGORITHM for [\(y),\(x)]*\(level):\n\(baseUrl)/\(region)/\(size)/\(rotation)/\(quality).\(format)")
        
        return URL(string: "\(baseUrl)/\(region)/\(size)/\(rotation)/\(quality).\(format)")
    }

}
