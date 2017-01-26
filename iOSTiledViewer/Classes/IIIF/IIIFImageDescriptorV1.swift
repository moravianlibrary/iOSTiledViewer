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
    
    fileprivate let _tileSize: CGSize
    fileprivate var _scaleFactors: [CGFloat]?
    fileprivate var _formats: Set<String> = ["jpg"]
    fileprivate var _currentFormat = "jpg"
    fileprivate var _qualities: Set<String> = ["native"]
    fileprivate var _currentQuality = "native"
    fileprivate var _error: NSError?
    
    // Optional fields
    fileprivate var _complianceUrl: String?
    fileprivate var _canvasSize: CGSize!
    fileprivate var _maxScale: CGFloat = 0
    fileprivate var _minScale: CGFloat = 0
    
    init(_ json: [String:Any]) {
        
        // required fields
        _baseUrl = json["@id"] as! String
        _width = json["width"] as! Int
        _height = json["height"] as! Int
        
        _complianceUrl = json["profile"] as? String
        
        if let qualities = json["qualities"] as? [String] {
            _qualities.formUnion(Set<String>(qualities))
        }
        
        if let format = json["formats"] as? [String] {
            _formats.formUnion(Set<String>(format))
        }
        
        if let scaleFactors = json["scale_factors"] as? [Int] {
            _scaleFactors = scaleFactors.map({ CGFloat($0) })
        }
        
        let height = json["tile_height"] as? Int
        let width = json["tile_width"] as? Int
        if width != nil {
            _tileSize = CGSize(width: width!, height: (height != nil ? height! : width!))
        } else if height != nil {
            _tileSize = CGSize(width: height!, height: height!)
        } else {
            _tileSize = CATiledLayer().tileSize
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
    
    var tileSize: [CGSize] {
        let levelCount = _scaleFactors != nil ? _scaleFactors!.count : 1
        return Array<CGSize>(repeating: _tileSize, count: levelCount)
    }
    
    var zoomScales: [CGFloat] {
        if _scaleFactors != nil {
            var scales = [_minScale]
            for s in _scaleFactors! where _minScale < s && s <= _maxScale {
                scales.append(s)
            }
            return scales
        } else {
            return [1]
        }
    }
    
    var formats: [String]? {
        return _formats.map({ $0 })
    }
    
    var format: String? {
        set {
            if newValue != nil && _formats.contains(newValue!) {
                _currentFormat = newValue!
            }
        }
        get {
            return _currentFormat
        }
    }
    
    var qualities: [String]? {
        return _qualities.map({ $0 })
    }
    
    var quality: String? {
        set {
            if newValue != nil && _qualities.contains(newValue!) {
                _currentQuality = newValue!
            }
        }
        get {
            return _currentQuality
        }
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
        var tile = _tileSize
        while tile.width > size.width || tile.height > size.height {
            tile.width /= 2
            tile.height /= 2
        }
        _canvasSize = IIIFImageDescriptor.sizeToFit(size: tile, imageW: width, imageH: height)
        
        adjustToFit(size: size)
        return _canvasSize
    }
    
    func adjustToFit(size: CGSize) {
        let imageSize = CGSize(width: width, height: height)
        let minRatioW = size.width / _canvasSize.width
        let minRatioH = size.height / _canvasSize.height
        let maxRatioW = imageSize.width / _canvasSize.width
        let maxRatioH = imageSize.height / _canvasSize.height
        _maxScale = max(maxRatioW, maxRatioH)
        _minScale = min(min(minRatioW, minRatioH), _maxScale)
    }
    
    func getBackgroundUrl() -> URL? {
        let region = "full"
        let size = "\(Int(_canvasSize.width)),\(Int(_canvasSize.height))"
        let rotation = "0"
        
        return URL(string: "\(baseUrl)/\(region)/\(size)/\(rotation)/\(_currentQuality).\(_currentFormat)")
    }
    
    func getUrl(x: Int, y: Int, level: Int, scale: CGFloat) -> URL? {
        // size of full image content
        let fullSize = CGSize(width: _width, height: _height)
        
        let (region, size) = IIIFImageDescriptor.getUrl(x: x, y: y, scale: scale, tile: _tileSize, fullSize: fullSize)
        let rotation = "0"
        
//        print("USED ALGORITHM for [\(y),\(x)]*\(level)(\(s)):\n\(baseUrl)/\(region)/\(size)/\(rotation)/\(_currentQuality).\(_currentFormat)")
        
        return URL(string: "\(baseUrl)/\(region)/\(size)/\(rotation)/\(_currentQuality).\(_currentFormat)")
    }
}
