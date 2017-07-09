//
//  ITVScrollViewGestureDelegate.swift
//  Pods
//
//  Created by Jakub Fiser on 09/07/2017.
//
//

/**
 Protocol for receiving gesture events from ITVScrollView class. Delegate will be informed about single tap, double tap and rotation after any of these events occure.
 */
@objc public protocol ITVScrollViewGestureDelegate {
    
    /**
     Method is called right after any of single or double tap event occurs.
     
     - parameter type: 
     - parameter location:
     */
    func didTap(type: ITVGestureEventType, location: CGPoint)
    
//    /**
//     Method is called right after a rotation event occurs.
//     
//     - parameter angle: Angle of rotation in degrees
//     */
//    func didRotate(angle: CGFloat)
}
