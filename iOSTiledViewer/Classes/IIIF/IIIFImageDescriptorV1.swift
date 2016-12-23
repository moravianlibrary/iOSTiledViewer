//
//  IIIFImageDescriptorV1.swift
//  Pods
//
//  Created by Jakub Fiser on 18/11/2016.
//
//

import UIKit

class IIIFImageDescriptorV1 {
    
    fileprivate let _baseUrl: String
    fileprivate let _height: Int
    fileprivate let _width: Int
    
    fileprivate var _tileSize: CGSize?
    fileprivate var _scaleFactors: [CGFloat]?
    fileprivate var _formats: Set<String>?
    fileprivate var _qualities: Set<String>?
    fileprivate var _error: NSError?
    
    // Optional fields
    fileprivate var _complianceUrl: String?
    fileprivate var _canvasSize: CGSize!
    
    init(_ json: [String:Any]) {
        
        // required fields
        _baseUrl = json["@id"] as! String
        _width = json["width"] as! Int
        _height = json["height"] as! Int
        
        _complianceUrl = json["profile"] as? String
        
        if let qualities = json["qualities"] as? [String] {
            _qualities = Set<String>(qualities)
        }
        
        if let format = json["formats"] as? [String] {
            _formats = Set<String>(format)
        }
        
        if let scaleFactors = json["scale_factors"] as? [Int] {
            _scaleFactors = scaleFactors.map({ CGFloat($0) })
        }
        
        let height = json["tile_height"] as? Int
        let width = json["tile_width"] as? Int
        if width != nil {
            _tileSize = CGSize(width: width!, height: (height != nil ? height! : width!))
        } else if height != nil {
            _tileSize = CGSize(width: (width != nil ? width! : height!), height: height!)
        }
    }
}

/// ITVImageDescriptor protocol implementation
extension IIIFImageDescriptorV1: ITVImageDescriptor {
    
    // Properties
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
        let levelCount = _scaleFactors != nil ? _scaleFactors!.count : 1
        return _tileSize != nil ? Array<CGSize>(repeating: _tileSize!, count: levelCount) : nil
    }
    
    var zoomScales: [CGFloat] {
        return _scaleFactors != nil ? _scaleFactors! : [1]
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

    // Methods
    func sizeToFit(size: CGSize) -> CGSize {
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
        
        if _scaleFactors != nil {
            var modifiedScales = [CGFloat]()
            let maxScale = CGFloat(width) / aspectFitSize.width
            for var scale in _scaleFactors! where scale < maxScale {
                modifiedScales.append(scale)
            }
            if !modifiedScales.contains(maxScale) {
                modifiedScales.append(maxScale)
            }
            _scaleFactors = modifiedScales
        }
        
        return aspectFitSize
    }
    
    func getBackgroundUrl() -> URL? {
        let region = "full"
        let size = "\(Int(_canvasSize.width)),\(Int(_canvasSize.height))"
        let rotation = "0"
        let quality = _qualities != nil ? _qualities!.first! : "native"
        let format = _formats != nil ? _formats!.first! : "jpg"
        
        return URL(string: "\(baseUrl)/\(region)/\(size)/\(rotation)/\(quality).\(format)")
    }
    
    func getUrl(x: Int, y: Int, level: Int, scale: CGFloat) -> URL? {
        // size of full image content
        let fullSize = CGSize(width: width, height: height)
        
        // tile size
        let tileSize: CGSize
        if let ts = self.tileSize?[level] {
            tileSize = ts
        }
        else {
            // default size
            tileSize = CATiledLayer().tileSize
        }
        
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
        let quality = _qualities != nil ? _qualities!.first! : "native"
        let format = _formats != nil ? _formats!.first! : "jpg"
        
//        print("USED ALGORITHM for [\(y),\(x)]*\(level)(\(s)):\n\(baseUrl)/\(region)/\(size)/\(rotation)/\(quality).\(format)")
        
        return URL(string: "\(baseUrl)/\(region)/\(size)/\(rotation)/\(quality).\(format)")
    }
}
