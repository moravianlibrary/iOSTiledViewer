//
//  RawImageDescriptor.swift
//  Bond
//
//  Created by Jakub Fiser on 25/11/2017.
//

import Foundation
import SDWebImage

/**
 Image descriptor that represents direct image files of formats JPG, PNG, GIF or WebP.
 */
class RawImageDescriptor {

    let baseUrl: String
    let height: Int
    let width: Int
    var zoomScales: [CGFloat] = [1]
    var error: NSError?

    init?(_ data: Data, _ url: String) {
        guard let img = UIImage.sd_image(with: data) else {
            return nil
        }

        baseUrl = url
        height = Int(img.size.height)
        width = Int(img.size.width)
    }
}


extension RawImageDescriptor: ITVImageDescriptor {

    var tileSize: [CGSize] {
        return []
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


    func getUrl(x: Int, y: Int, level: Int) -> URL? {
        return nil
    }

    func getBackgroundUrl() -> URL? {
        return URL(string: baseUrl)
    }

    func sizeToFit(size: CGSize) -> CGSize {
        let ratioW = CGFloat(width) / size.width
        let ratioH = CGFloat(height) / size.height
        let ratio = max(ratioW, ratioH)
        let newSize = CGSize(width: CGFloat(width)/ratio, height: CGFloat(height)/ratio)
        adjustToFit(size: newSize)
        return newSize
    }

    func adjustToFit(size: CGSize) {
        let maxScale = CGFloat(width) / size.width
        var i: CGFloat = 1
        zoomScales = []
        while i < maxScale {
            zoomScales.append(i)
            i *= 2
        }
        zoomScales.append(maxScale)
    }
}
