//
//  ITVImageDescriptor.swift
//  Pods
//
//  Created by Jakub Fiser on 20/10/2016.
//
//

/**
 Abstract class representing an image. It should contain all the required information to construct a request for a given zoom level and coordinates. It also contains methods for image related computations, such as initial size to fit screen, minimum and maximum zoom scale, etc.
 */
protocol ITVImageDescriptor {

    // Required fields
    /// Base image url address. It is used to build an url for specific tile requests.
    var baseUrl: String { get }
    /// Full image height.
    var height: Int { get }
    /// Full image width.
    var width: Int { get }
    /// Tile size for each level.
    var tileSize: [CGSize] { get }
    /// Zoom scales.
    var zoomScales: [CGFloat] { get }
    /// Image formats.
    var formats: [String]? { get }
    /// Returns current format
    var format: String? { get set }
    /// Image qualities.
    var qualities: [String]? { get }
    /// Returns current quality
    var quality: String? { get set }
    /// Error description or nil.
    var error: NSError? { get set }
    
    
    /// Method returns constructed URL address for specific zoom level and x,y coordinates.
    func getUrl(x: Int, y: Int, level: Int) -> URL?
    
    /// Returns an Url for background image
    func getBackgroundUrl() -> URL?
    
    /// Returns new size for the image according its metadata
    func sizeToFit(size: CGSize) -> CGSize
    
    /** 
     Method for recomputing some important informations for resizing
     - returns: new size for the image when maximum scale has been modified, or CGSize.zero when only minimum scale was modified
     
     TODO: Not the best way to do resizing, should return for example tuple like (size, minScale, maxScale). But could the minimum scale be 1.0 or screen scale when resizing IIIF images?
     */
    func adjustToFit(size: CGSize)
}
