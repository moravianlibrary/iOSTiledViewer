//
//  ITVScrollView.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

import UIKit

/// Enum of supported image apis.
@objc public enum ITVImageAPI: Int {
    /// IIIF Image API
    case IIIF
    /// Zoomify API
    case Zoomify
    /// Raw image which does not support any APIs above. Supported formats are jpg, png, gif and webp
    case Raw
    /// Some other API
    case Unknown
}

/// Enum of supported gesture events.
@objc public enum ITVGestureEventType: Int {
    case singleTap
    case doubleTap
//    case rotation
}

/**
 The main class of the iOSTiledViewer library. All communication is done throught this class. See example project to see how to set correctly the class. It has to be initialized through storyboard.
 Assign ITVErrorDelegate to receive errors related to displaying images. The assignment should be done before calling `loadImage(_:)` or `loadImage(_:api:)` method to ensure you receive all errors.
 */
open class ITVScrollView: UIScrollView {
    
    /// Delegate for receiving errors and some important events.
    public var itvDelegate: ITVScrollViewDelegate? {
        didSet {
            containerView.itvDelegate = itvDelegate
        }
    }
    
    /// Delegate for receiving gesture events.
    public var itvGestureDelegate: ITVScrollViewGestureDelegate?
    
    /// Events that ITVScrollView handles automatically. Default is all. Though there is currently no automatic operation for singleTap. Note that this does not prevent delegating about missing events.
    public var handleGestureEvents: [ITVGestureEventType] = [.singleTap, .doubleTap]
    
    /// Returns true only if content is not scaled.
    public var isZoomedOut: Bool {
        return self.zoomScale <= self.minimumZoomScale
    }
    
    /// Returns an array of possible image formats as Strings.
    public var imageFormats: [String]? {
        return containerView.image?.formats
    }
    
    /// Returns and sets current image format
    public var currentFormat: String? {
        get {
            return containerView.image?.format
        }
        set {
            containerView.image?.format = newValue
            containerView.loadBackground()
            containerView.clearCache()
            containerView.refreshTiles()
        }
    }
    
    /// Returns an array of possible image qualities as Strings.
    public var imageQualities: [String]? {
        return containerView.image?.qualities
    }
    
    /// Returns and sets current image quality
    public var currentQuality: String? {
        get {
            return containerView.image?.quality
        }
        set {
            containerView.image?.quality = newValue
            containerView.loadBackground()
            containerView.clearCache()
            containerView.refreshTiles()
        }
    }
    
    /// Returns array of possible zoom scales.
    public var zoomScales: [CGFloat] {
        return containerView.image?.zoomScales ?? [1]
    }
    
    open override var bounds: CGRect {
        didSet {
            // update scales when bounds change
            if let img = containerView.image {
                recomputeSize(image: img)
            }
        }
    }

    fileprivate let supportedImageFormats = ["jpg", "png", "gif", "webp"]
    fileprivate let containerView = ITVContainerView()
    fileprivate let licenseView = ITVLicenceView()
    fileprivate var lastLevel: Int = -1
    fileprivate var minBounceScale: CGFloat = 0
    fileprivate var maxBounceScale: CGFloat = 0
    fileprivate var singleTapRecognizer: UITapGestureRecognizer!
    fileprivate var doubleTapRecognizer: UITapGestureRecognizer!

    /// Property stores currently displayed file's url.
    public fileprivate(set) var url: String?
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
        // set scroll view delegate
        delegate = self
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bounces = false
        
        // add container view with tiled and background views
        addSubview(containerView)
        containerView.initTiledView()
        
        // add license view
        superview?.addSubview(licenseView)
        licenseView.translatesAutoresizingMaskIntoConstraints = false
        superview?.addConstraints([
            NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: licenseView, attribute: .trailing, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: licenseView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .lessThanOrEqual, toItem: licenseView, attribute: .leading, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .lessThanOrEqual, toItem: licenseView, attribute: .top, multiplier: 1.0, constant: 0)
            ])
        
        // add double tap to zoom
        doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap(recognizer:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delegate = self
        addGestureRecognizer(doubleTapRecognizer)
        
        singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSingleTap(recognizer:)))
        singleTapRecognizer.delegate = self
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(singleTapRecognizer)
    }
    
    /**
     Call this method to rotate an image.
     
     - parameter angle: Degrees in range <-360, 360>
     - note: Rotation has not been implemented yet.
     */
    public func rotateImage(angle: CGFloat) {
        guard case -360...360 = angle else {
            print("Invalid rotation with angle: \(angle).")
            return
        }
        print("Rotate function has not been implemented yet.")
    }
    
    /**
     Method for loading image. If api 'Unknown' is passed then the method will try to automatically recognize the api. This could include synchronous network requests.
     
     - parameter imageUrl: URL string of image to load.
     - parameter api: Specify image api that should be used. Default is 'Unknown'
     */
    public func loadImage(_ imageUrl: String, api: ITVImageAPI = .Unknown) {
        self.url = imageUrl
        var url: String?
        switch api {
        case .IIIF:
            if !imageUrl.contains(IIIFImageDescriptor.propertyFile) {
                url = imageUrl + (imageUrl.last != "/" ? "/" : "") + IIIFImageDescriptor.propertyFile
            } else {
                url = imageUrl
            }

        case .Zoomify:
            if !imageUrl.contains(ZoomifyImageDescriptor.propertyFile) {
                url = imageUrl + (imageUrl.last != "/" ? "/" : "") + ZoomifyImageDescriptor.propertyFile
            } else {
                url = imageUrl
            }

        case .Raw:
            url = imageUrl

        case .Unknown:
            loadImage(imageUrl)
            return
        }
        loadUrl(url, api: api)
    }
    
    /**
     Method for zooming.
     
     - parameter scale: Scale to zoom.
     - parameter animated: Animation flag.
     */
    public func zoomToScale(_ scale: CGFloat, animated: Bool) {
        setZoomScale(scale, animated: animated)
    }
    
    /// Method for releasing cached images when device runs low on memory. Should be called by UIViewController when needed.
    public func didRecieveMemoryWarning() {
        containerView.clearCache()
    }
    
    /// Use to immediately refresh layout
    public func refreshTiles() {
        containerView.refreshTiles()
    }
    
    fileprivate var lastZoomScale: CGFloat = 0
    fileprivate var doubleTapToZoom = true
    /** 
     Method that changes zoom without user interaction accordingly:
     - if current zoom is equal to minimal zoom, then zoom will be increased
     - if current zoom is equal to maximal zoom, then zoom will be decreased
     - if last zooming was increasing, then zoom will be increased as well
     - if last zooming was decreasing, then zoom will be decreased as well
     */
    public func performDoubleTapZoom() {
        let level = lastLevel + (doubleTapToZoom ? 1 : -1)
        zoomToScale(pow(2.0, CGFloat(level)), animated: true)
    }
}


internal extension ITVScrollView {
    
    @objc internal func didDoubleTap(recognizer: UITapGestureRecognizer) {
        if handleGestureEvents.contains(.doubleTap) {
            performDoubleTapZoom()
        }
        
        let location = recognizer.location(in: self)
        itvGestureDelegate?.didTap(type: .doubleTap, location: location)
    }
    
    @objc internal func didSingleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self)
        itvGestureDelegate?.didTap(type: .singleTap, location: location)
    }
}


fileprivate extension ITVScrollView {
    
    // Reinitialize all important variables to their defaults
    fileprivate func initVariables() {
        // reset double tap to zoom variables
        lastZoomScale = 0
        doubleTapToZoom = true
        
        // reset bouncing
        minBounceScale = 0.2
        maxBounceScale = 1.8
        
        // default scale
        lastLevel = -1
        minimumZoomScale = 1.0
        maximumZoomScale = 1.0
        zoomScale = minimumZoomScale
        
        // clear container view
        containerView.clearViews()
        containerView.frame = CGRect(origin: CGPoint.zero, size: frame.size)
    }
    
    // Resizing tiled view to fit in scroll view
    fileprivate func resizeTiledView(image: ITVImageDescriptor) {
        let newSize = image.sizeToFit(size: frame.size)
        containerView.frame = CGRect(origin: CGPoint.zero, size: newSize)
        scrollViewDidZoom(self)
    }
    
    // Recompute scales by actual frame size and set minimumZoomScale
    fileprivate func recomputeSize(image: ITVImageDescriptor) {
        guard !isZooming, !isZoomBouncing else {
            return
        }
        
        image.adjustToFit(size: frame.size)
        let wasZoomedOut = isZoomedOut
        setScaleLimits(image: image)
        if wasZoomedOut {
            zoomScale = minimumZoomScale
        }
        
        scrollViewDidZoom(self)
    }
    
    fileprivate func setScaleLimits(image: ITVImageDescriptor) {
        let scales = image.zoomScales
        maximumZoomScale = scales.max()!
        minimumZoomScale = scales.min()!
        
        let minLevel = Int(round(log2(minimumZoomScale)))
        let maxLevel = Int(round(log2(maximumZoomScale)))
        minBounceScale = pow(2.0, CGFloat(minLevel - 1)) + 0.2
        maxBounceScale = pow(2.0, CGFloat(maxLevel + 1)) - 0.2
    }
    
    // Initializing tiled view and scroll view's zooming
    fileprivate func initWithDescriptor(_ imageDescriptor: ITVImageDescriptor?) {
        guard var image = imageDescriptor, image.error == nil else {
            let error = imageDescriptor?.error ?? NSError(domain: Constants.TAG, code: 100, userInfo: [Constants.USERINFO_KEY:"Error getting image information."])
            itvDelegate?.didFinishLoading(error: error)
            return
        }
        
        image.format = currentFormat
        image.quality = currentQuality
        
        initVariables()
        resizeTiledView(image: image)
        setScaleLimits(image: image)
        zoomScale = minimumZoomScale
        changeLevel(forScale: minimumZoomScale)
        containerView.image = image
        licenseView.imageDescriptor = image
        
        itvDelegate?.didFinishLoading(error: nil)
    }
    
    // Synchronous test for url content download
    fileprivate func testUrlContent(_ stringUrl: String) -> Bool {
        guard let url = URL(string: stringUrl) else {
            return false
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var result = false
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                result = true
            }
            semaphore.signal()
        }).resume()
        
        semaphore.wait()
        return result
    }
    
    fileprivate func changeLevel(forScale scale: CGFloat) {
        // redraw image by setting contentScaleFactor on tiledView
        let level = max(Int(round(log2(scale))), 0)
        if level != lastLevel {
            containerView.tiledView.contentScaleFactor = pow(2.0, CGFloat(level))
            lastLevel = level
        }
    }

    /**
     Method for loading image.
     - parameter imageUrl: URL of image to load. Currently only IIIF and Zoomify images are supported. For IIIF images, pass in URL to property file or containing "/full/full/0/default.jpg". For Zoomify images, pass in URL to property file or url containing "TileGroup". All other urls won't be recognized and ITVErrorDelegate will be noticed.
     */
    fileprivate func loadImage(_ imageUrl: String) {
        var url: String?
        var api = ITVImageAPI.Unknown
        if imageUrl.contains(IIIFImageDescriptor.propertyFile) ||
            imageUrl.contains(ZoomifyImageDescriptor.propertyFile) {
            // address is prepared for loading
            url = imageUrl
            api = imageUrl.contains(IIIFImageDescriptor.propertyFile) ? .IIIF : .Zoomify
        } else if imageUrl.lowercased().contains("/full/full/0/default.jpg") {
            // IIIF image, but url needs to be modified in order to download image information first
            url = imageUrl.replacingOccurrences(of: "full/full/0/default.jpg", with: IIIFImageDescriptor.propertyFile, options: .caseInsensitive, range: imageUrl.startIndex..<imageUrl.endIndex)
            api = .IIIF
        } else if imageUrl.contains("TileGroup") {
            // Zoomify image, but url needs to be modified in order to download image information first
            let endIndex = imageUrl.range(of: "TileGroup")!.lowerBound
            let startIndex = imageUrl.startIndex
            url = imageUrl[startIndex..<endIndex] + ZoomifyImageDescriptor.propertyFile
            api = .Zoomify
        } else if supportedImageFormats.contains(imageUrl.components(separatedBy: ".").last!) {
            url = imageUrl
            api = .Raw
        } else {
            // try one and decide by result
            var testUrl = imageUrl
            if testUrl.last != "/" {
                testUrl += "/"
            }

            DispatchQueue.global().async {
                if self.testUrlContent(testUrl + ZoomifyImageDescriptor.propertyFile) {
                    url = testUrl + ZoomifyImageDescriptor.propertyFile
                    api = .Zoomify
                } else if self.testUrlContent(testUrl + IIIFImageDescriptor.propertyFile) {
                    url = testUrl + IIIFImageDescriptor.propertyFile
                    api = .IIIF
                } else {
                    let error = NSError(domain: Constants.TAG, code: 100, userInfo: [Constants.USERINFO_KEY:"Url \(imageUrl) does not support IIIF or Zoomify API."])
                    DispatchQueue.main.async {
                        self.itvDelegate?.didFinishLoading(error: error)
                    }
                }
                self.loadUrl(url, api: api)
            }
            return
        }
        loadUrl(url, api: api)
    }

    /**
     Method for downloading image information data and initializing subviews.
     - parameter url: URL string of image to load.
     - parameter api: API
     */
    fileprivate func loadUrl(_ urlString: String?, api: ITVImageAPI) {
        guard urlString != nil, let url = URL(string: urlString!) else {
            return
        }

        self.url = urlString
        var block: ((Data?, URLResponse?, Error?) -> Void)? = nil
        switch api {
        case .IIIF:
            block = {(data, response, error) in
                let code = (response as? HTTPURLResponse)?.statusCode
                if code == 200, data != nil, let serialization = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) {

                    let imageDescriptor = IIIFImageDescriptor.versionedDescriptor(serialization as! [String : Any])
                    DispatchQueue.main.async {
                        self.initWithDescriptor(imageDescriptor)
                    }
                } else {
                    let error = NSError(domain: Constants.TAG, code: 100, userInfo: [Constants.USERINFO_KEY:"Error loading IIIF image information."])
                    DispatchQueue.main.async {
                        self.itvDelegate?.didFinishLoading(error: error)
                    }
                }
            }
        case .Zoomify:
            block = {(data, response, error) in
                let code = (response as? HTTPURLResponse)?.statusCode
                if code == 200, data != nil, let json = SynchronousZoomifyXMLParser().parse(data!) {

                    let imageDescriptor = ZoomifyImageDescriptor(json, self.url!)
                    DispatchQueue.main.async {
                        self.initWithDescriptor(imageDescriptor)
                    }
                } else {
                    let error = NSError(domain: Constants.TAG, code: 100, userInfo: [Constants.USERINFO_KEY:"Error loading Zoomify image information."])
                    DispatchQueue.main.async {
                        self.itvDelegate?.didFinishLoading(error: error)
                    }
                }
            }
        case .Raw:
            block = {(data, response, error) in
                let code = (response as? HTTPURLResponse)?.statusCode
                if code == 200, data != nil, let imageDescriptor = RawImageDescriptor(data!, self.url!) {
                    DispatchQueue.main.async {
                        self.initWithDescriptor(imageDescriptor)
                    }
                } else {
                    let error = NSError(domain: Constants.TAG, code: 100, userInfo: [Constants.USERINFO_KEY:"Error loading raw image information."])
                    DispatchQueue.main.async {
                        self.itvDelegate?.didFinishLoading(error: error)
                    }
                }
            }
        default:
            return
        }

        guard block != nil else {
            // unsupported image API, should never happen here
            let error = NSError(domain: Constants.TAG, code: 100, userInfo: [Constants.USERINFO_KEY:"Unsupported image API."])
            itvDelegate?.didFinishLoading(error: error)
            return
        }

        URLSession.shared.dataTask(with: url, completionHandler: block!).resume()
    }
}


/// MARK: UIScrollViewDelegate implementation
extension ITVScrollView: UIScrollViewDelegate {
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // decide the way of double tap zoom
        if zoomScale >= maximumZoomScale {
            doubleTapToZoom = false
        } else if zoomScale <= minimumZoomScale {
            doubleTapToZoom = true
        } else if lastZoomScale != zoomScale {
            doubleTapToZoom = (lastZoomScale < zoomScale)
        }
        lastZoomScale = zoomScale
        
        // limit bounce scale to prevent incorrect placed tiles
        if zoomScale < minBounceScale {
            zoomScale = minBounceScale
        } else if zoomScale > maxBounceScale {
            zoomScale = maxBounceScale
        }
        
        // center the image as it becomes smaller than the size of the screen
        let boundsSize = bounds.size
        let f = containerView.frame
        containerView.frame.origin.x = (f.size.width < boundsSize.width) ? (boundsSize.width - f.size.width) / 2 : 0
        containerView.frame.origin.y = (f.size.height < boundsSize.height) ? (boundsSize.height - f.size.height) / 2 : 0
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        changeLevel(forScale: scale)
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
}


/// MARK: UIGestureRecognizerDelegate implementation
extension ITVScrollView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let myGestures: Set = [singleTapRecognizer, doubleTapRecognizer]
        let eventGestures: Set = [gestureRecognizer, otherGestureRecognizer]
        return eventGestures.isSubset(of: myGestures)
    }
}
