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
    fileprivate var _maxScale: CGFloat = 1
    fileprivate var _minScale: CGFloat = 1
    fileprivate var _maxLevel: Int = 0
    
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
            _tileSize = CGSize(width: width!, height: (height ?? width!))
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
        let levelCount = _scaleFactors?.count ?? 1
        return Array<CGSize>(repeating: _tileSize, count: levelCount)
    }
    
    var zoomScales: [CGFloat] {
        var scales = [_minScale]
        if _scaleFactors != nil {
            for s in _scaleFactors! where _minScale < s && s <= _maxScale {
                scales.append(s)
            }
        }
        if !scales.contains(_maxScale) {
            scales.append(_maxScale)
        }
        return scales
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
            _error = newValue
        }
    }

    
    // Methods
    func sizeToFit(size: CGSize) -> CGSize {
        let tile = _tileSize
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
        _maxLevel = Int(round(log2(_maxScale)))
    }
    
    func getBackgroundUrl() -> URL? {
        let region = "full"
        let size = "\(Int(_canvasSize.width)),\(Int(_canvasSize.height))"
        let rotation = "0"
        
        return URL(string: "\(baseUrl)/\(region)/\(size)/\(rotation)/\(_currentQuality).\(_currentFormat)")
    }
    
    func getUrl(x: Int, y: Int, level: Int) -> URL? {
        // size of full image content
        let fullSize = CGSize(width: _width, height: _height)
        let s: CGFloat = pow(2.0, CGFloat(_maxLevel - level))
        
        let rotation = "0"
        guard let (region, size) = IIIFImageDescriptor.getUrl(x: x, y: y, scale: s, tile: _tileSize, fullSize: fullSize) else {
            return nil
        }
        
//        print("USED ALGORITHM for [\(y),\(x)]*\(level)(\(s)):\n\(baseUrl)/\(region)/\(size)/\(rotation)/\(_currentQuality).\(_currentFormat)")
        
        return URL(string: "\(baseUrl)/\(region)/\(size)/\(rotation)/\(_currentQuality).\(_currentFormat)")
    }
}
