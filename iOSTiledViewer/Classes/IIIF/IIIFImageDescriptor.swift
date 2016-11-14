//
//  IIIFImageDescriptor.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

enum IIIFFormat: String {
    case GIF = "gif"
    case JPG = "jpg"
    case JP2 = "jp2"
    case PDF = "pdf"
    case PNG = "png"
    case TIF = "tif"
    case WEBP = "webp"
}

enum IIIFQuality: String {
    case Default = "default"
    case Bitonal = "bitonal"
    case Gray = "gray"
    case Color = "color"
}


/**
 Class representing all the information about specific image. This class conforms to IIIFImage API of version 2.1.
 */
class IIIFImageDescriptor: ITVImageDescriptor {
    
    static let propertyFile = "info.json"
    
    // Optional fields
    var formats: Set<IIIFFormat>?
    var maxArea: Int?
    var maxWidth: Int?
    var maxHeight: Int?
    var qualities: Set<IIIFQuality>?
    var supports: Set<String>?
    
    var sizes: Array<CGSize>?
    
    var tiles: IIIFImageTile?
    
    var license: IIIFImageLicense?
    
    init(_ json: [String:Any]) {
        
        // required fields
        let bUrl = json["@id"] as! String
        let w = json["width"] as! Int
        let h = json["height"] as! Int
        super.init(baseUrl: bUrl, height: h, width: w)
        
        if let profile = json["profile"] as? [Any] {
            for profileItem in profile {
                if let profileObj = profileItem as? [String: Any] {
                    if let format = profileObj["formats"] as? [String] {
                        self.formats = Set<IIIFFormat>()
                        for item in format {
                            self.formats!.insert(IIIFFormat(rawValue: item)!)
                        }
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
                        self.qualities = Set<IIIFQuality>()
                        for item in qualities {
                            self.qualities!.insert(IIIFQuality(rawValue: item)!)
                        }
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
            self.tiles = IIIFImageTile(tiles.first!)
        }
        
        if json["attribution"] != nil || json["logo"] != nil || json["license"] != nil {
            self.license = IIIFImageLicense(json)
        }
    }
    
    override func getTileSize(level: Int) -> CGSize {
        return tiles!.size!
    }
    
    override func getMaximumZoomScale() -> CGFloat {
        let maximumScale = tiles?.scaleFactors?.first
        return (maximumScale != nil ? maximumScale! : 1)
    }
    
    override func getMinimumZoomScale(size: CGSize, viewScale: CGFloat) -> CGFloat {
        return 1
    }
    
    override func getImageFormats() -> [String] {
        return (formats != nil ? formats!.map({ (item) -> String in return item.rawValue }) : [])
    }
    
    override func getImageQualities() -> [String] {
        return (qualities != nil ? qualities!.map({ (item) -> String in return item.rawValue }) : [])
    }
    
    override func sizeToFit(size: CGSize, zoomScale: CGFloat) -> CGSize {
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
        return aspectFitSize
    }
    
    override func getUrl(x: Int, y: Int, level: Int, scale: CGFloat) -> URL? {
        // size of full image content
        let fullSize = CGSize(width: width, height: height)
        
        // tile size
        let tileSize = getTileSize(level: level)
        
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
        let quality = "default"
        let format = "jpg"
        
//        print("USED ALGORITHM for [\(y),\(x)]*\(level)(\(s)):\n\(baseUrl)/\(region)/\(size)/\(rotation)/\(quality).\(format)")
        
        return URL(string: "\(baseUrl)/\(region)/\(size)/\(rotation)/\(quality).\(format)")
    }
}
