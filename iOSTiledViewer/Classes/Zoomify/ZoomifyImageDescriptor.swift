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
    fileprivate let _pyramid: [ZoomifyLevel]
    fileprivate var _zoomScales: [CGFloat]!
    fileprivate var _error: NSError?
    
    fileprivate let _tileSize: CGSize
    fileprivate var _canvasSize: CGSize!
    fileprivate let depth: Int
    fileprivate let numTiles: Int
    fileprivate var _tilesUpToLevel = [0]
    
    init(_ json: [String:String], _ url: String) {
        
        _baseUrl = url.replacingOccurrences(of: "/\(ZoomifyImageDescriptor.propertyFile)", with: "")
        _height = Int(json["HEIGHT"]!)!
        _width = Int(json["WIDTH"]!)!
        
        let tileW = Int(json["TILESIZE"]!)!
        _tileSize = CGSize(width: tileW, height: tileW)
        
        // pyramid
        var pyramid = [ZoomifyLevel]()
        var level = ZoomifyLevel(_width, _height, tileW)
        while level.width > tileW || level.height > tileW {
            pyramid.append(level)
            level = ZoomifyLevel( level.width / 2, level.height / 2, tileW )
        }
        pyramid.append(level)
        _pyramid = pyramid.reversed()
        
        // maximum image depth
        depth = _pyramid.count
        
        // count tile numbers for each level
        var count: Int
        for level in _pyramid {
            count = level.tilesX * level.tilesY
            count += _tilesUpToLevel.last!
            _tilesUpToLevel.append(count)
        }
        numTiles = _tilesUpToLevel.last!
    }
    
    fileprivate func tilesOnLevel(_ lvl: Int) -> Int {
        let level = _pyramid[lvl - 1]
        return level.tilesX * level.tilesY
    }
    
    fileprivate func tilesUpToLevel(_ level: Int) -> Int {
        return _tilesUpToLevel[level]
    }
    
    fileprivate func tilesUpToLevel(_ level: CGFloat) -> Int {
        return tilesUpToLevel(Int(level))
    }
    
    fileprivate func saveZoomScales(_ originalSize: CGSize, _ aspectFitSize: CGSize) {
        let ratioW = originalSize.width / aspectFitSize.width
        let ratioH = originalSize.height / aspectFitSize.height
        let minimumScale = min(ratioW, ratioH)
        _zoomScales = [minimumScale]
        for i in 1...depth-1 {
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
    
    var tileSize: [CGSize] {
        return Array(repeating: _tileSize, count: depth)
    }
    
    var zoomScales: [CGFloat] {
        return _zoomScales
    }
    
    var formats: [String]? {
        return nil
    }
    
    var format: String? {
        get {
            return nil
        }
        set {}
    }
    
    var qualities: [String]? {
        return nil
    }
    
    var quality: String? {
        get {
            return nil
        }
        set {}
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
        return getUrl(x: 0, y: 0, level: 0)
    }
    
    func getUrl(x: Int, y: Int, level: Int) -> URL? {
        
        guard case 0...depth-1 = level else {
            return nil
        }
        let zoomifyLevel = _pyramid[level]
        guard case 0...zoomifyLevel.tilesX-1 = x,
            case 0...zoomifyLevel.tilesY-1 = y else {
            return nil
        }
        
        let indexY = zoomifyLevel.tilesX
        let index = x + y * indexY + tilesUpToLevel(level)
        
        let group = "TileGroup\(index/256)"
        let file = "\(level)-\(x)-\(y)"
        let format = "jpg"
        
//        print("USED ALGORITHM for [\(y),\(x)]*\(level):\n\(baseUrl)/\(group)/\(file).\(format)")
        return URL(string: "\(baseUrl)/\(group)/\(file).\(format)")
    }
    
    func sizeToFit(size: CGSize) -> CGSize {
        // scale full image size to level zero
        let imageSize = CGSize(width: width, height: height)
        let trasnformation = 2/CGFloat(powf(2.0, Float(depth)))
        _canvasSize = imageSize.applying(CGAffineTransform(scaleX: trasnformation, y: trasnformation))
        
        saveZoomScales(size, _canvasSize)
        return _canvasSize
    }
    
    func adjustToFit(size: CGSize) {
        saveZoomScales(size, _canvasSize)
    }
}
