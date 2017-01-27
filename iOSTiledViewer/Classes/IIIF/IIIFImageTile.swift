//
//  IIIFImageTile.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

struct IIIFImageTile {

    var size: CGSize!
    var scaleFactors: [CGFloat]!
    
    init?(_ json: [String:Any]) {
        
        guard let width = json["width"] as? Int,
              let scaleFactors = json["scaleFactors"] as? [Int] else {
            return nil
        }
        
        if let height = json["height"] as? Int {
            self.size = CGSize(width: width, height: height)
        }
        else {
            self.size = CGSize(width: width, height: width)
        }
        
        self.scaleFactors = scaleFactors.map({ CGFloat($0) })
    }
}
