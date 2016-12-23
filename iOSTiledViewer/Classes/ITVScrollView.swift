//
//  ITVScrollView.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

import UIKit

/// Enum of supported image apis.
public enum ITVImageAPI {
    /// IIIF Image API
    case IIIF
    /// Zoomify API
    case Zoomify
    /// Some other API
    case Unknown
}

/**
 The main class of the iOSTiledViewer library. All communication is done throught this class. See example project to see how to set correctly the class. It has to be initialized through storyboard.
 Assign ITVErrorDelegate to receive errors related to displaying images. The assignment should be done before calling `loadImage(_:)` or `loadImage(_:api:)` method to ensure you receive all errors. Test link: `ITVScrollView.itvDelegate`
 */
open class ITVScrollView: UIScrollView {
    
    /// Delegate for receiving errors and some important events.
    public var itvDelegate: ITVScrollViewDelegate?
    
    /// Returns true only if content is not scaled.
    public var isZoomedOut: Bool {
        return self.zoomScale == 1.0
    }
    
    /// Returns an array of image formats as Strings.
    public var imageFormats: [String]? {
        return tiledView.image.formats
    }
    
    /// Returns an array of image qualities as Strings.
    public var imageQualities: [String]? {
        return tiledView.image.qualities
    }
    
    /// Returns array of possible zoom scales.
    public var zoomScales: [CGFloat] {
        return tiledView.image.zoomScales
    }
    
    fileprivate let containerView = UIView()
    fileprivate let backgroundImage = UIImageView()
    fileprivate let backTiledView = ITVBackgroundView()
    fileprivate let tiledView = ITVTiledView()
    fileprivate let licenseView = ITVLicenceView()
    fileprivate var lastLevel: Int = -1
    fileprivate var url: String? {
        didSet {
            if url != nil {
                var block: ((Data?, URLResponse?, Error?) -> Void)? = nil
                if url!.contains(IIIFImageDescriptor.propertyFile) {
                    // IIIF
                    block = {(data, response, error) in
                        let code = (response as? HTTPURLResponse)?.statusCode
                        if code == 200, data != nil , let serialization = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) {
                            
                            let imageDescriptor = IIIFImageDescriptor.versionedDescriptor(serialization as! [String : Any])
                            DispatchQueue.main.sync {
                                self.initWithDescriptor(imageDescriptor)
                            }
                        } else {
                            let error = NSError(domain: Constants.TAG, code: 100, userInfo: [Constants.USERINFO_KEY:"Error loading IIIF image information."])
                            DispatchQueue.main.async {
                                self.itvDelegate?.didFinishLoading(error: error)
                            }
                        }
                    }
                }
                else if url!.contains(ZoomifyImageDescriptor.propertyFile) {
                    // Zoomify
                    block = {(data, response, error) in
                        let code = (response as? HTTPURLResponse)?.statusCode
                        if code == 200, data != nil , let json = SynchronousZoomifyXMLParser().parse(data!) {
                            
                            let imageDescriptor = ZoomifyImageDescriptor(json, self.url!)
                            DispatchQueue.main.sync {
                                self.initWithDescriptor(imageDescriptor)
                            }
                        } else {
                            let error = NSError(domain: Constants.TAG, code: 100, userInfo: [Constants.USERINFO_KEY:"Error loading Zoomify image information."])
                            DispatchQueue.main.async {
                                self.itvDelegate?.didFinishLoading(error: error)
                            }
                        }
                    }
                }
                
                guard block != nil else {
                    // unsupported image API, should never happen here
                    let error = NSError(domain: Constants.TAG, code: 100, userInfo: [Constants.USERINFO_KEY:"Unsupported image API."])
                    itvDelegate?.didFinishLoading(error: error)
                    return
                }
                
                URLSession.shared.dataTask(with: URL(string: url!)!, completionHandler:
                        block!).resume()
            }
        }
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
        // set scroll view delegate
        delegate = self
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        
        // register to receive notifications about orientation changes
        NotificationCenter.default.addObserver(self, selector: #selector(ITVScrollView.orientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        // add tiled and background views
        tiledView.backgroundView = backTiledView
        containerView.backgroundColor = UIColor.clear
        backgroundImage.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backTiledView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tiledView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(backgroundImage)
        containerView.addSubview(backTiledView)
        containerView.addSubview(tiledView)
        addSubview(containerView)
        
        // add license view
        superview?.addSubview(licenseView)
        licenseView.translatesAutoresizingMaskIntoConstraints = false
        superview?.addConstraints([
            NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: licenseView, attribute: .trailing, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: licenseView, attribute: .bottom, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .lessThanOrEqual, toItem: licenseView, attribute: .leading, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .lessThanOrEqual, toItem: licenseView, attribute: .top, multiplier: 1.0, constant: 0)
            ])
    }
    
    /**
     Call this method to rotate an image.
     
     - parameter angle: Number in range <-360, 360>
     */
    public func rotateImage(angle: CGFloat) {
        guard case -360...360 = angle else {
            print("Invalid rotation with angle: \(angle).")
            return
        }
        print("Rotate function has not been implemented yet.")
    }
    
    /**
     Method for loading image.
     
     - parameter imageUrl: URL of image to load.
     - parameter api: Specify image api. Currently can be of values IIIF, Zoomify and Unknown.
     */
    public func loadImage(_ imageUrl: String, api: ITVImageAPI) {
        switch api {
            case .IIIF:
                if !imageUrl.contains(IIIFImageDescriptor.propertyFile) {
                    url = imageUrl + (imageUrl.characters.last != "/" ? "/" : "") + IIIFImageDescriptor.propertyFile
                }
                else {
                    url = imageUrl
                }
                
            case .Zoomify:
                if !imageUrl.contains(ZoomifyImageDescriptor.propertyFile) {
                    url = imageUrl + (imageUrl.characters.last != "/" ? "/" : "") + ZoomifyImageDescriptor.propertyFile
                }
                else {
                    url = imageUrl
                }
            
            case .Unknown:
                loadImage(imageUrl)
        }
    }
    
    /**
     Method for zooming.
     
     - parameter scale: Scale to zoom.
     - parameter animated: Animation flag.
     */
    public func zoomToScale(_ scale: CGFloat, animated: Bool) {
        setZoomScale(scale, animated: animated)
    }
    
    // Resizing image on orientation changes.
    public func orientationDidChange() {
        
        guard let image = tiledView.image else {
            return
        }
        
        if isZoomedOut {
            // resize tiledView only when not zoomed in
            resizeTiledView(image: image)
        }
        else {
            // else check only for need of reposition
            scrollViewDidZoom(self)
        }
    }
    
    public func didRecieveMemoryWarning() {
        tiledView.clearCache()
        backTiledView.clearCache()
    }
}

fileprivate extension ITVScrollView {
    
    // Resizing tiled view to fit in scroll view
    fileprivate func resizeTiledView(image: ITVImageDescriptor) {
        var newSize = image.sizeToFit(size: frame.size)
        
        // round with precision to 0.1 to prevent blank space at right and bottom edge because of autoresizing masks
        newSize.width = round(newSize.width * 10.0) / 10.0
        newSize.height = round(newSize.height * 10.0) / 10.0
        
        containerView.frame = CGRect(origin: CGPoint.zero, size: newSize)
        scrollViewDidZoom(self)
    }
    
    // Initializing tiled view and scroll view's zooming
    fileprivate func initWithDescriptor(_ imageDescriptor: ITVImageDescriptor?) {
        guard var image = imageDescriptor, image.error == nil else {
            let error = imageDescriptor?.error != nil ? imageDescriptor!.error! : NSError(domain: Constants.TAG, code: 100, userInfo: [Constants.USERINFO_KEY:"Error getting image information."])
            itvDelegate?.didFinishLoading(error: error)
            return
        }
        
        resizeTiledView(image: image)
        let scales = image.zoomScales
        maximumZoomScale = scales.last!
        minimumZoomScale = scales.first!
        zoomScale = minimumZoomScale
        changeLevel(forScale: minimumZoomScale)
        loadBackground(image.getBackgroundUrl())
        tiledView.image = image
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
        let level = Int(round(log2(scale)))
        if level != lastLevel {
            tiledView.contentScaleFactor = pow(2.0, CGFloat(level))
            lastLevel = level
        }
    }

    /**
    */
    fileprivate func loadBackground(_ backgroundUrl: URL?) {
        backgroundImage.backgroundColor = UIColor.clear
        
        guard let url = backgroundUrl else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if data != nil, let image = UIImage(data: data!) {
                DispatchQueue.main.async {
                    self.backgroundImage.image = image
                }
            }
        }.resume()
    }

    /**
     Method for loading image.
     - parameter imageUrl: URL of image to load. Currently only IIIF and Zoomify images are supported. For IIIF images, pass in URL to property file or containing "/full/full/0/default.jpg". For Zoomify images, pass in URL to property file or url containing "TileGroup". All other urls won't be recognized and ITVErrorDelegate will be noticed.
     */
    fileprivate func loadImage(_ imageUrl: String) {
        
        if imageUrl.contains(IIIFImageDescriptor.propertyFile) ||
            imageUrl.contains(ZoomifyImageDescriptor.propertyFile) {
            // address is prepared for loading
            self.url = imageUrl
        }
        else if imageUrl.lowercased().contains("/full/full/0/default.jpg") {
            // IIIF image, but url needs to be modified in order to download image information first
            self.url = imageUrl.replacingOccurrences(of: "full/full/0/default.jpg", with: IIIFImageDescriptor.propertyFile, options: .caseInsensitive, range: imageUrl.startIndex..<imageUrl.endIndex)
        }
        else if imageUrl.contains("TileGroup") {
            // Zoomify image, but url needs to be modified in order to download image information first
            let endIndex = imageUrl.range(of: "TileGroup")!.lowerBound
            let startIndex = imageUrl.startIndex
            self.url = imageUrl.substring(with: startIndex..<endIndex) + ZoomifyImageDescriptor.propertyFile
        }
        else {
            // try one and decide by result
            var testUrl = imageUrl
            if testUrl.characters.last != "/" {
                testUrl += "/"
            }
            
            if testUrlContent(testUrl + ZoomifyImageDescriptor.propertyFile) {
                self.url = testUrl + ZoomifyImageDescriptor.propertyFile
            }
            else if testUrlContent(testUrl + IIIFImageDescriptor.propertyFile) {
                self.url = testUrl + IIIFImageDescriptor.propertyFile
            }
            else {
                let error = NSError(domain: Constants.TAG, code: 100, userInfo: [Constants.USERINFO_KEY:"Url \(imageUrl) does not support IIIF or Zoomify API."])
                itvDelegate?.didFinishLoading(error: error)
            }
        }
    }
}

/// MARK: UIScrollViewDelegate implementation
extension ITVScrollView: UIScrollViewDelegate {
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // center the image as it becomes smaller than the size of the screen
        let boundsSize = bounds.size
        let f = containerView.frame
        
        // center horizontally
        containerView.frame.origin.x = (f.size.width < boundsSize.width) ? (boundsSize.width - f.size.width) / 2 : 0
        
        // center vertically
        containerView.frame.origin.y = (f.size.height < boundsSize.height) ? (boundsSize.height - f.size.height) / 2 : 0
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        changeLevel(forScale: scale)
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return containerView
    }
}
