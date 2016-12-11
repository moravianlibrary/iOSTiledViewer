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
    var tileSize: [CGSize]? { get }
    /// Zoom scales.
    var zoomScales: [CGFloat] { get }
    /// Image formats.
    var formats: [String]? { get }
    /// Image qualities.
    var qualities: [String]? { get }
    /// Error description or nil.
    var error: NSError? { get set }
    
    
    /// Method returns constructed URL address for specific zoom level and x,y coordinates.
    func getUrl(x: Int, y: Int, level: Int, scale: CGFloat) -> URL?
    
    ///
    func getBackgroundUrl() -> URL?
    
    /// Note - Protocol may be implemented by struct, that would need to store size and scale values for further computations. To allow that, function has to be marked as mutating.
    mutating func sizeToFit(size: CGSize) -> CGSize
}
