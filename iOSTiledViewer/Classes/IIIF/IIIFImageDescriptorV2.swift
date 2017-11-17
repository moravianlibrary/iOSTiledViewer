//
//  IIIFImageDescriptorV2.swift
//  Pods
//
//  Created by Jakub Fiser on 18/11/2016.
//
//

import UIKit

class IIIFImageDescriptorV2 {
    
    fileprivate let _baseUrl: String
    fileprivate let _height: Int
    fileprivate let _width: Int
    fileprivate var _tiles: [IIIFImageTile]?
    fileprivate var _currentFormat = "jpg"
    fileprivate var _currentQuality = "default"
    fileprivate var _error: NSError?
    
    // Optional fields
    fileprivate var _profile = IIIFImageProfileV2()
    fileprivate var sizes: Array<CGSize>?
    fileprivate var _canvasSize: CGSize!
    fileprivate var _maxScale: CGFloat = 1
    fileprivate var _minScale: CGFloat = 1
    fileprivate var _maxLevel: Int = 0
    var license: IIIFImageLicense?
    
    init(_ json: [String:Any]) {
        
        // required fields
        _baseUrl = json["@id"] as! String
        _width = json["width"] as! Int
        _height = json["height"] as! Int
        
        if let profile = json["profile"] as? [Any] {
            for profileItem in profile {
                if let profileObj = profileItem as? [String: Any] {
                    // parse additional info in profile
                    _profile.append(json: profileObj)
                } else if let profileUrl = profileItem as? String, let url = URL(string: profileUrl) {
                    // download additional info from profile url
                    // is not synchronized yet as completion handler is currently being called on the same thread and it causes deadlock
                    URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
                        if data != nil, let serialization = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) {
                            let profileObj = serialization as! [String: Any]
                            self._profile.append(json: profileObj)
                        }
                    }).resume()
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
    
    var tileSize: [CGSize] {
        if _tiles != nil {
            var result = [CGSize]()
            for tile in _tiles! {
                result.append(contentsOf: Array<CGSize>(repeating: tile.size, count: tile.scaleFactors.count))
            }
            return result
        } else {
            return [CATiledLayer().tileSize]
        }
    }
    
    var zoomScales: [CGFloat] {
        var scales = [_minScale]
        if _tiles != nil {
            for tile in _tiles! {
                for s in tile.scaleFactors where _minScale < s && s <= _maxScale {
                    scales.append(s)
                }
            }
        }
        if !scales.contains(_maxScale) {
            scales.append(_maxScale)
        }
        return scales
    }
    
    var formats: [String]? {
        return _profile.formats.map({ $0 })
    }
    
    var format: String? {
        set {
            if newValue != nil && _profile.formats.contains(newValue!) {
                _currentFormat = newValue!
            }
        }
        get {
            return _currentFormat
        }
    }
    
    var qualities: [String]? {
        return _profile.qualities.map({ $0 })
    }
    
    var quality: String? {
        set {
            if newValue != nil && _profile.qualities.contains(newValue!) {
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
        let tile = tileSize.first!
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
        
        // tile size
        let tile: CGSize
        if case 0..<tileSize.count = level {
            tile = tileSize[level]
        } else {
            tile = tileSize.last!
        }
        let s: CGFloat = pow(2.0, CGFloat(_maxLevel - level))
        
        let rotation = "0"
        guard let (region, size) = IIIFImageDescriptor.getUrl(x: x, y: y, scale: s, tile: tile, fullSize: fullSize) else {
            return nil
        }
        
//        print("USED ALGORITHM for [\(y),\(x)]*\(level)(\(s)):\n\(baseUrl)/\(region)/\(size)/\(rotation)/\(_currentQuality).\(_currentFormat)")
        
        return URL(string: "\(baseUrl)/\(region)/\(size)/\(rotation)/\(_currentQuality).\(_currentFormat)")
    }
}
