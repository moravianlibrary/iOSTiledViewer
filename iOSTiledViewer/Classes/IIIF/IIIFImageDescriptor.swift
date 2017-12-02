//
//  IIIFImageDescriptor.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

/**
 Class representing all the information about specific image. This class conforms to IIIFImage API of version 2.1.
 */
class IIIFImageDescriptor {
    
    static let propertyFile = "info.json"
    fileprivate static let version1Context = "http://library.stanford.edu/iiif/image-api/1.1/context.json"
    fileprivate static let version2Context = "http://iiif.io/api/image/2/context.json"
    
    static func versionedDescriptor(_ json: [String:Any]) -> ITVImageDescriptor? {
        let context = json["@context"] as! String
        if context == version1Context {
            return IIIFImageDescriptorV1(json)
        }
        else if context == version2Context {
            return IIIFImageDescriptorV2(json)
        }
        else {
            // TODO: return empty struct with error implementing ITVImageDescriptor protocol
//            let _error = NSError(domain: Constants.TAG, code: 100, userInfo: [Constants.USERINFO_KEY:"Unsupported IIIF Image version."])
            return nil
        }
    }
    
    fileprivate init() {}
    
    static func sizeToFit(size: CGSize, imageW width: Int, imageH height: Int) -> CGSize {
        var aspectFitSize = CGSize(width: width, height: height)
        let t = CGAffineTransform(scaleX: 0.5, y: 0.5)
        while aspectFitSize.width > size.width || aspectFitSize.height > size.height {
            // while the scaled image size doesn't fit in given size, continue reducing it
            aspectFitSize = aspectFitSize.applying(t)
        }
        
        // return image size that fully fits in the given size
        return aspectFitSize
    }
    
    static func getUrl(x: Int, y: Int, scale: CGFloat, tile: CGSize, fullSize: CGSize) -> (String, String)? {
        return getUrl(x: CGFloat(x), y: CGFloat(y), scale: scale, tile: tile, fullSize: fullSize)
    }
    
    static func getUrl(x: CGFloat, y: CGFloat, scale: CGFloat, tile: CGSize, fullSize: CGSize) -> (String, String)? {
        
        // Calculate region parameters /xr,yr,wr,hr/
        let xr = x * tile.width * scale
        let yr = y * tile.height * scale
        var wr = tile.width * scale
        if (xr + wr > fullSize.width) {
            wr = fullSize.width - xr
        }
        var hr = tile.height * scale
        if (yr + hr > fullSize.height) {
            hr = fullSize.height - yr
        }
        
        guard case 0...fullSize.width = xr,
              case 0...fullSize.width = wr,
              case 0...fullSize.height = yr,
              case 0...fullSize.height = hr else {
                // return nil when computed coordinates lay beyond the image bounds
            return nil
        }
        
        let region = "\(Int(xr)),\(Int(yr)),\(Int(wr)),\(Int(hr))"
        let size = "\(Int(tile.width)),\(tile.height == tile.width ? "" : String(Int(tile.height)))"
        
        return (region, size)
    }
}
