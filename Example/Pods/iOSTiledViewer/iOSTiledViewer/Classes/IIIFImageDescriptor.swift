//
//  IIIFImageDescriptor.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

enum IIIFFormat: String {
    case JPG = "jpg"
    case PNG = "png"
    case GIF = "gif"
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
class IIIFImageDescriptor: NSObject {

    // Required fields
    let baseUrl: String
    let height: Int
    let width: Int
    
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
        baseUrl = json["@id"] as! String
        width = json["width"] as! Int
        height = json["height"] as! Int
        
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
}
