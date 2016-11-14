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
/// TODO: There is high probability that this class will be refactored as a protocol.
class ITVImageDescriptor: NSObject {

    // Required fields
    /// Base image url address. It is used to build an url for specific tile requests.
    let baseUrl: String
    /// Full image height.
    let height: Int
    /// Full image width.
    let width: Int
    
    init(baseUrl: String, height: Int, width: Int) {
        self.baseUrl = baseUrl
        self.height = height
        self.width = width
    }
    
    /// Method returns constructed URL address for specific zoom level and x,y coordinates.
    func getUrl(x: Int, y: Int, level: Int, scale: CGFloat) -> URL? {
        fatalError("getUrl(level:, x:, y:) has not been implemented.")
    }
    
    /// Returns tile size for the given zoom level.
    func getTileSize(level: Int) -> CGSize {
        fatalError("getTileSize(level:) has not been implemented.")
    }
    
    func getMaximumZoomScale() -> CGFloat {
        fatalError("getMaximumZoomScale() has not been implemented.")
    }
    
    func getMinimumZoomScale(size: CGSize, viewScale: CGFloat) -> CGFloat {
        fatalError("getMinimumZoomScale() has not been implemented.")
    }
    
    func getImageFormats() -> [String] {
        fatalError("getImageFormats() has not been implemented.")
    }
    
    func getImageQualities() -> [String] {
        fatalError("getImageQualities() has not been implemented.")
    }
    
    func sizeToFit(size: CGSize, zoomScale: CGFloat) -> CGSize {
        fatalError("sizeToFit(size:, zoomScale:) has not been implemented.")
    }
}
