//
//  IIIFImageDescriptorV2.swift
//  Pods
//
//  Created by Jakub Fiser on 18/11/2016.
//
//

import UIKit

struct IIIFImageDescriptorV2 {
    
    fileprivate let _baseUrl: String
    fileprivate let _height: Int
    fileprivate let _width: Int
    fileprivate var _tiles: [IIIFImageTile]?
    fileprivate var _formats: Set<String>?
    fileprivate var _qualities: Set<String>?
    fileprivate var _error: NSError?
    
    // Optional fields
    fileprivate var maxArea: Int?
    fileprivate var maxWidth: Int?
    fileprivate var maxHeight: Int?
    fileprivate var supports: Set<String>?
    fileprivate var sizes: Array<CGSize>?
    fileprivate var _canvasSize: CGSize!
    var license: IIIFImageLicense?
    
    init(_ json: [String:Any]) {
        
        // required fields
        _baseUrl = json["@id"] as! String
        _width = json["width"] as! Int
        _height = json["height"] as! Int
        
        if let profile = json["profile"] as? [Any] {
            for profileItem in profile {
                if let profileObj = profileItem as? [String: Any] {
                    if let format = profileObj["formats"] as? [String] {
                        _formats = Set<String>(format)
                    }
                    if let maxArea = profileObj["maxArea"] as? Int {
                        self.maxArea = maxArea
                    }
                    if let maxHeight = profileObj["maxHeight"] as? Int {
                        self.maxHeight = maxHeight
                    }
                    if let maxWidth = profileObj["maxWidth"] as? Int {
                        self.maxWidth = maxWidth
                        if self.maxHeight == nil {
                            self.maxHeight = self.maxWidth
                        }
                    }
                    if let qualities = profileObj["qualities"] as? [String] {
                        _qualities = Set<String>(qualities)
                    }
                    if let supports = profileObj["supports"] as? [String] {
                        self.supports = Set<String>()
                        for item in supports {
                            self.supports?.insert(item)
                        }
                    }
                }
            }
        }
        
        
        if let sizes = json["sizes"] as? [[String:Int]] {
            self.sizes = Array<CGSize>()
            for item in sizes {
                let width = CGFloat(item["width"]!)
                let height = CGFloat(item["height"]!)
                self.sizes!.append(CGSize(width: width, height: height))
            }
        }
        
        if let tiles = json["tiles"] as? [[String:Any]] {
            self._tiles = [IIIFImageTile]()
            for tile in tiles {
                if let iiifTile = IIIFImageTile(tile) {
                    self._tiles!.append(iiifTile)
                }
            }
        }
        
        if json["attribution"] != nil || json["logo"] != nil || json["license"] != nil {
            self.license = IIIFImageLicense(json)
        }
    }
}

/// ITVImageDescriptor protocol implementation
extension IIIFImageDescriptorV2: ITVImageDescriptor {
    
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
        var result = [CGSize]()
        if _tiles != nil {
            for _tile in _tiles! {
                result.append(contentsOf: Array<CGSize>(repeating: _tile.size, count: _tile.scaleFactors.count))
            }
        }
        return result.isEmpty ? nil : result
    }
    
    var zoomScales: [CGFloat] {
        var result = [CGFloat]()
        if _tiles != nil {
            for _tile in _tiles! {
                result.append(contentsOf: _tile.scaleFactors)
            }
        }
        return result.isEmpty ? [1] : result
    }
    
    var formats: [String]? {
        return _formats?.map({ $0 })
    }
    
    var qualities: [String]? {
        return _qualities?.map({ $0 })
    }
    
    var error: NSError? {
        get {
            return _error
        }
        set {
            _error = error
        }
    }
    
    
    mutating func sizeToFit(size: CGSize) -> CGSize {
        let imageSize = CGSize(width: width, height: height)
        var aspectFitSize = size
        let mW = aspectFitSize.width / imageSize.width
        let mH = aspectFitSize.height / imageSize.height
        if mH <= mW {
            aspectFitSize.width = mH * imageSize.width
        }
        else if mW <= mH {
            aspectFitSize.height = mW * imageSize.height
        }
        _canvasSize = aspectFitSize
        return aspectFitSize
    }
    
    func getBackgroundUrl() -> URL? {
        let region = "full"
        let size = "\(Int(_canvasSize.width)),\(Int(_canvasSize.height))"
        let rotation = "0"
        let quality = _qualities != nil ? _qualities!.first! : "default"
        let format = _formats != nil ? _formats!.first! : "jpg"
        
        return URL(string: "\(baseUrl)/\(region)/\(size)/\(rotation)/\(quality).\(format)")
    }
    
    func getUrl(x: Int, y: Int, level: Int, scale: CGFloat) -> URL? {
        // size of full image content
        let fullSize = CGSize(width: width, height: height)
        
        // tile size
        let tileSize = self.tileSize![level]
        
        // scale factor
        let s: CGFloat = scale
        
        // tile coordinate (col)
        let n: CGFloat = CGFloat(x)
        
        // tile coordinate (row)
        let m: CGFloat = CGFloat(y)
        
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
        
        let region = "\(Int(xr)),\(Int(yr)),\(Int(wr)),\(Int(hr))"
        let size = "\(Int(tileSize.width)),\(tileSize.height == tileSize.width ? "" : String(Int(tileSize.height)))"
        let rotation = "0"
        let quality = _qualities != nil ? _qualities!.first! : "default"
        let format = _formats != nil ? _formats!.first! : "jpg"
        
//        print("USED ALGORITHM for [\(y),\(x)]*\(level)(\(s)):\n\(baseUrl)/\(region)/\(size)/\(rotation)/\(quality).\(format)")
        
        return URL(string: "\(baseUrl)/\(region)/\(size)/\(rotation)/\(quality).\(format)")
    }
}
