//
//  IIIFImageTile.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

class IIIFImageTile: NSObject {

    var size: CGSize?
    var scaleFactors: [CGFloat]?
    
    init(_ json: [String:Any]) {
        
        if let height = json["height"] as? Int {
            let width = json["width"] as! Int
            self.size = CGSize(width: width, height: height)
        }
        else if let width = json["width"] as? Int {
            self.size = CGSize(width: width, height: width)
        }
        
        if let scaleFactors = json["scaleFactors"] as? [Int] {
            self.scaleFactors = Array<CGFloat>()
            for item in scaleFactors {
                self.scaleFactors!.append(CGFloat(item))
            }
            self.scaleFactors!.reverse()
        }
    }
}
