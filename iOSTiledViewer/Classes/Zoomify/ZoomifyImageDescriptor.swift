//
//  ZoomifyImageDescriptor.swift
//  Pods
//
//  Created by Jakub Fiser on 20/10/2016.
//
//

import UIKit

class ZoomifyImageDescriptor {
    
    static let propertyFile = "ImageProperties.xml"
    
    fileprivate let _baseUrl: String
    fileprivate let _height: Int
    fileprivate let _width: Int
    fileprivate var _zoomScales: [CGFloat]!
    fileprivate var _error: NSError?
    
    fileprivate var _tileSize: CGSize!
    fileprivate var depth: Int!
    fileprivate var numberOfTiles: Int?
    fileprivate var tilesForLevel = [0,1]
    
    
    init(_ json: [String:String], _ url: String) {
        
        _baseUrl = url.replacingOccurrences(of: "/\(ZoomifyImageDescriptor.propertyFile)", with: "")
        _height = Int(json["HEIGHT"]!)!
        _width = Int(json["WIDTH"]!)!
        
        let tileW = Int(json["TILESIZE"]!)!
        _tileSize = CGSize(width: tileW, height: tileW)
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
    
    fileprivate func tilesOnLevel(_ lvl: Int) -> Int {
        return tilesForLevel[lvl+1] - tilesForLevel[lvl]
    }
    
    fileprivate func numberOfTiles(_ level: Int) -> Int {
        return tilesForLevel[level]
    }
    
    fileprivate func numberOfTiles(_ level: CGFloat) -> Int {
        return numberOfTiles(Int(level))
    }
    
    fileprivate func saveZoomScales(_ originalSize: CGSize, _ aspectFitSize: CGSize) {
        let ratioW = originalSize.width / aspectFitSize.width
        let ratioH = originalSize.height / aspectFitSize.height
        let minimumScale = min(ratioW, ratioH)
        _zoomScales = [minimumScale]
        for i in 1...depth {
            let scale = CGFloat(powf(2, Float(i)))
            if scale > minimumScale {
                _zoomScales.append(scale)
            }
        }
    }
}

extension ZoomifyImageDescriptor: ITVImageDescriptor {
    
    var baseUrl: String {
        return _baseUrl
    }
    
    var height: Int {
        return _height
    }
    
    var width: Int {
        return _width
    }
    
    var tileSize: [CGSize]? {
        return Array(repeating: _tileSize, count: depth)
    }
    
    var zoomScales: [CGFloat] {
        return _zoomScales
    }
    
    var formats: [String]? {
        return nil
    }
    
    var qualities: [String]? {
        return nil
    }
    
    var error: NSError? {
        get {
            return _error
        }
        set {
            _error = error
        }
    }
    
    func getBackgroundUrl() -> URL? {
        return getUrl(x: 0, y: 0, level: 0, scale: 0)
    }
    
    func getUrl(x: Int, y: Int, level: Int, scale: CGFloat) -> URL? {
        
        let exponent = powf(2, Float(depth - level))
        let tileWidth = Float(_tileSize.width)
        let indexY = Int(ceil(floor(Float(width)/exponent)/tileWidth))
        let index = x + y * indexY + numberOfTiles(level)
        
        let group = "TileGroup\(index/256)"
        let file = "\(level)-\(x)-\(y)"
        let format = "jpg"
        
//        print("USED ALGORITHM for [\(y),\(x)]*\(level):\n\(baseUrl)/\(group)/\(file).\(format)")
        
        return URL(string: "\(baseUrl)/\(group)/\(file).\(format)")
    }
    
    func sizeToFit(size: CGSize) -> CGSize {
        // We have to
        let totalTiles = Float(tilesOnLevel(depth))
        let numTilesX = CGFloat(width) / _tileSize.width
        let numTilesY = CGFloat(height) / _tileSize.height
        let tile = _tileSize.width / Constants.SCREEN_SCALE
        
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
        
        let trasnformation = Constants.SCREEN_SCALE/CGFloat(powf(2.0, Float(depth)))
        aspectFitSize = aspectFitSize.applying(CGAffineTransform(scaleX: trasnformation, y: trasnformation))
        
        saveZoomScales(size, aspectFitSize)
        return aspectFitSize
    }
}
