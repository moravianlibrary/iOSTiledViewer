//
//  ITVScrollViewDelegate.swift
//  Pods
//
//  Created by Jakub Fiser on 09/11/2016.
//
//

/**
 Protocol that should be implemented by object using iOSTiledViewer library. You receive errors and other important information about image states and image itself.
 */
@objc public protocol ITVScrollViewDelegate {
    
    /**
     Method called right after image source is recognized and it's property file is downloaded. In this moment you can ask ITVScrollView for the minimum and maximum zoom scale and other image properties.
     
     - parameter error: Is nil if no error occurs, otherwise see userInfo for more details about error.
     */
    func didFinishLoading(error: NSError?)
    
    /**
     Method called on error occurence. It is called only when didFinishLoading(error:) method has been called before.
     
     - parameter error: See userInfo for more details about error.
    */
    func errorDidOccur(error: NSError)
}
