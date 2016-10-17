//
//  ITVTiledView.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

import UIKit

class ITVTiledView: UIView {

    fileprivate;; let TAG = "ITVTiledView"
    fileprivate;; var imageCache = [String:UIImage]()
    
    internal var imageBaseUrl: String?
    
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
    
    override var contentScaleFactor: CGFloat {
        didSet {
            // save some memory
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
        
        let scaleX = context.ctm.a
        let scaleY = context.ctm.d
        
        let tiledLayer = self.layer as! CATiledLayer
        var tileSize = tiledLayer.tileSize
        
        tileSize.width /= scaleX
        tileSize.height /= -scaleY
        
        let firstCol = Int(rect.minX / tileSize.width)
        let lastCol = Int((rect.maxX - 1) / tileSize.width)
        let firstRow = Int(rect.minY / tileSize.height)
        let lastRow = Int((rect.maxY - 1) / tileSize.height)
        
        let level = Int(self.contentScaleFactor)
        
        var requestURL: URL!
        let displayTileBorders = true
        
        for row in firstRow...lastRow {
            for col in firstCol...lastCol {
                
//                let tileRect = CGRect(x: tileSize.width * CGFloat(col), y: tileSize.height * CGFloat(row), width: tileSize.width, height: tileSize.height)

//                let tileCacheKey = "\(level)/\(col)_\(row)"
                let cacheKey = "\(col)_\(row)"
                if let image = imageCache[cacheKey] {
//                    let intersect = rect.intersection(CGRect(origin: rect.origin, size: image.size))
//                    image.draw(in: intersect)
                    image.draw(in: rect)
                }
                else {
                    requestURL = self.tiledImageView(col, y: row, level: level)
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
        }
    }
    
    func tiledImageView(_ x: Int, y: Int, level: Int=1) -> URL! {
        
        // size of full image content
        let fullSize = CGSize(width: image.width, height: image.height)
        
        // tile size
        let tileSize = image.tiles?.size != nil ? image.tiles!.size! : (layer as! CATiledLayer).tileSize
        
        // scale factor
        let s = CGFloat(Int(sqrt(Double(level))))
        
        // tile coordinate (col)
        let n = CGFloat(x)
        
        // tile coordinate (row)
        let m = CGFloat(y)
        
        // Calculate region parameters /xr,yr,wr,hr/
        let xr = n * tileSize.width / s
        let yr = m * tileSize.height / s
        var wr = tileSize.width / s
        if (xr + wr > fullSize.width) {
            wr = fullSize.width - xr
        }
        var hr = tileSize.height / s
        if (yr + hr > fullSize.height) {
            hr = fullSize.height - yr
        }
        
        // Calculate size parameters /ws,hs/
//        var ws = tileSize.width
//        if (xr + tileSize.width*s > fullSize.width) {
//            ws = (fullSize.width - xr + s - 1) / s  // +s-1 in numerator to round up
//        }
//        var hs = tileSize.height
//        if (yr + tileSize.height*s > fullSize.height) {
//            hs = (fullSize.height - yr + s - 1) / s
//        }
        
        let baseUrl = image.baseUrl
        let region = "\(Int(xr)),\(Int(yr)),\(Int(wr)),\(Int(hr))"
        let size = "\(Int(tileSize.width)),\(tileSize.height == tileSize.width ? "" : String(Int(tileSize.height)))"
        let rotation = "0"
        let quality = "default"
        let format = "jpg"
        
        print("USED ALGORITHM for [\(y),\(x)] * \(level):\n\(baseUrl)/\(region)/\(size)/\(rotation)/\(quality).\(format)")
        
        return URL(string: "\(baseUrl)/\(region)/\(size)/\(rotation)/\(quality).\(format)")
    }

}
