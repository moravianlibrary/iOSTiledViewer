//
//  ZoomifyLevel.swift
//  Pods
//
//  Created by Jakub Fiser on 22/01/2017.
//
//

struct ZoomifyLevel {
    
    let width: Int
    let height: Int
    let tilesX: Int
    let tilesY: Int
    
    init(_ w: Int, _ h: Int, _ tile: Int) {
        width = w
        height = h
        tilesX = Int(ceil(Float(width)/Float(tile)))
        tilesY = Int(ceil(Float(height)/Float(tile)))
    }
}
