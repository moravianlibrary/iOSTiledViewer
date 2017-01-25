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
            _error = error
        }
    }
    
    
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
        
        if _tiles != nil {
            let maxScale = CGFloat(width) / aspectFitSize.width
            for tile in _tiles! {
                var modifiedScale = [CGFloat]()
                for scale in tile.scaleFactors where scale < maxScale {
                    modifiedScale.append(scale)
                }
                if !tile.scaleFactors.elementsEqual(modifiedScale) && !modifiedScale.contains(maxScale) {
                    modifiedScale.append(maxScale)
                }
                tile.scaleFactors = modifiedScale
            }
        }
        
        return aspectFitSize
    }
    
    func getBackgroundUrl() -> URL? {
        let region = "full"
        let size = "\(Int(_canvasSize.width)),\(Int(_canvasSize.height))"
        let rotation = "0"
        
        return URL(string: "\(baseUrl)/\(region)/\(size)/\(rotation)/\(_currentQuality).\(_currentFormat)")
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
        
//        print("USED ALGORITHM for [\(y),\(x)]*\(level)(\(s)):\n\(baseUrl)/\(region)/\(size)/\(rotation)/\(_currentQuality).\(_currentFormat)")
        
        return URL(string: "\(baseUrl)/\(region)/\(size)/\(rotation)/\(_currentQuality).\(_currentFormat)")
    }
}
