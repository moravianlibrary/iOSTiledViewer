//
//  ITVDelegate.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

import UIKit

public protocol ITVDelegate {

    func isZoomedOut() -> Bool
    
    func loadImage(_ imageUrl: String)
}
