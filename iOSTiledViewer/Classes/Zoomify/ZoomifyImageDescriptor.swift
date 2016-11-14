//
//  ZoomifyImageDescriptor.swift
//  Pods
//
//  Created by Jakub Fiser on 20/10/2016.
//
//

import UIKit

class ZoomifyImageDescriptor: ITVImageDescriptor, XMLParserDelegate {
    
    static let propertyFile = "ImageProperties.xml"
    
    var tileSize: CGSize!
    var depth: Int!
    var numberOfTiles: Int?
    
    fileprivate var tilesForLevel = [0,1]
    
    init(_ json: [String:String], _ url: String) {
        
        let bUrl = url.replacingOccurrences(of: "/\(ZoomifyImageDescriptor.propertyFile)", with: "")
        let h = Int(json["HEIGHT"]!)!
        let w = Int(json["WIDTH"]!)!
        super.init(baseUrl: bUrl, height: h, width: w)
        
        let tileW = Int(json["TILESIZE"]!)!
        tileSize = CGSize(width: tileW, height: tileW)
        numberOfTiles = Int(json["NUMTILES"]!)
        
        // maximum image depth
        var depth = 1
        var size = max(height, width)/tileW
        while size != 1 {
            size /= 2
            depth += 1
        }
        self.depth = depth
        
        // count tile numbers for each level
        let floatW = Float(width)
        let floatH = Float(height)
        let tile = Float(tileW)
        var count = 0
        var tilesX = 0
        var tilesY = 0
        var exponent: Float = 0
        for i in 1...depth {
            exponent = powf(2.0, Float(depth - i))
            tilesX = Int(ceil(floor(floatW/exponent)/tile))
            tilesY = Int(ceil(floor(floatH/exponent)/tile))
            count = tilesX * tilesY
            count += tilesForLevel.last!
            tilesForLevel.append(count)
        }
    }
    
    override func getUrl(x: Int, y: Int, level: Int, scale: CGFloat) -> URL? {
        
        let exponent = powf(2, Float(depth - level))
        let tileWidth = Float(getTileSize(level: level).width)
        let indexY = Int(ceil(floor(Float(width)/exponent)/tileWidth))
        let index = x + y * indexY + numberOfTiles(level)
        
        let group = "TileGroup\(index/256)"
        let file = "\(level)-\(x)-\(y)"
        let format = "jpg"
        
//        print("USED ALGORITHM for [\(y),\(x)]*\(level):\n\(baseUrl)/\(group)/\(file).\(format)")
        
        return URL(string: "\(baseUrl)/\(group)/\(file).\(format)")
    }
    
    override func getTileSize(level: Int) -> CGSize {
        return tileSize
    }
    
    override func getMaximumZoomScale() -> CGFloat {
        return CGFloat(powf(2, Float(depth)))
    }
    
    override func getMinimumZoomScale(size: CGSize, viewScale: CGFloat) -> CGFloat {
        let minimumSize = sizeToFit(size: size, zoomScale: viewScale)
        let ratioW = size.width / minimumSize.width
        let ratioH = size.height / minimumSize.height
        
        return min(ratioW, ratioH)
    }
    
    override func getImageFormats() -> [String] {
        return ["jpg"]
    }
    
    override func getImageQualities() -> [String] {
        return ["default"]
    }
    
    override func sizeToFit(size: CGSize, zoomScale: CGFloat) -> CGSize {
        let sum = Float(width + height)
        let totalTiles = Float(numberOfTiles(2) - numberOfTiles(1))
        let numTilesX = CGFloat(round(totalTiles / (sum / Float(width))))
        let numTilesY = CGFloat(round(totalTiles / (sum / Float(height))))
        let tile = tileSize.width / zoomScale
        
        let imageSize = CGSize(width: width, height: height)
        var aspectFitSize = CGSize(width: numTilesX*tile, height: numTilesY*tile)
        let mW = aspectFitSize.width / imageSize.width
        let mH = aspectFitSize.height / imageSize.height
        if mH <= mW {
            aspectFitSize.width = mH * imageSize.width
        }
        else if mW <= mH {
            aspectFitSize.height = mW * imageSize.height
        }
        return aspectFitSize
    }
    
    fileprivate func numberOfTiles(_ level: Int) -> Int {
        return tilesForLevel[level]
    }
}
