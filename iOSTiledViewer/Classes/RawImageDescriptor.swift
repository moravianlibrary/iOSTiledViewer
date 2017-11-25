//
//  RawImageDescriptor.swift
//  Bond
//
//  Created by Jakub Fiser on 25/11/2017.
//

import Foundation

/**
 Image descriptor that represents direct image files of formats JPG, PNG, GIF or WebP.
 */
class RawImageDescriptor {

    fileprivate let _baseUrl: String
    fileprivate let _height: Int
    fileprivate let _width: Int
    fileprivate var _zoomScales: [CGFloat] = [1]
    fileprivate var _error: NSError?

    init?(_ data: Data, _ url: String) {
        guard let img = UIImage.sd_image(with: data) else {
            return nil
        }

        _baseUrl = url
        _height = Int(img.size.height)
        _width = Int(img.size.width)
    }
}


extension RawImageDescriptor: ITVImageDescriptor {

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
        return []
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
            _error = newValue
        }
    }


    func getUrl(x: Int, y: Int, level: Int) -> URL? {
        return nil
    }

    func getBackgroundUrl() -> URL? {
        return URL(string: _baseUrl)
    }

    func sizeToFit(size: CGSize) -> CGSize {
        let ratioW = CGFloat(_width) / size.width
        let ratioH = CGFloat(_height) / size.height
        let ratio = max(ratioW, ratioH)
        let newSize = CGSize(width: CGFloat(_width)/ratio, height: CGFloat(_height)/ratio)
        adjustToFit(size: newSize)
        return newSize
    }

    func adjustToFit(size: CGSize) {
        let maxScale = CGFloat(_width) / size.width
        var i: CGFloat = 1
        _zoomScales = []
        while i < maxScale {
            _zoomScales.append(i)
            i *= 2
        }
        _zoomScales.append(maxScale)
    }
}
