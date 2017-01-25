//
//  IIIFImageProfileV2.swift
//  Pods
//
//  Created by Jakub Fiser on 25/01/2017.
//
//

import UIKit

class IIIFImageProfileV2 {
    
    var maxArea: Int?
    var maxHeight: Int?
    var maxWidth: Int?
    var formats: Set<String> = ["jpg"]
    var qualities: Set<String> = ["default"]
    var supports: Set<String>?
    
    func append(json: [String: Any]) {
        if let value = json["maxArea"] as? Int {
            maxArea = value
        }
        if let value = json["maxHeight"] as? Int {
            maxHeight = value
        }
        if let value = json["maxWidth"] as? Int {
            maxWidth = value
            if maxHeight == nil {
                maxHeight = maxWidth
            }
        }
        if let value = json["formats"] as? [String] {
            formats.formUnion(Set<String>(value))
        }
        if let value = json["qualities"] as? [String] {
            qualities.formUnion(Set<String>(value))
        }
        if let value = json["supports"] as? [String] {
            supports = Set<String>(value)
        }
    }
}
