//
//  ITVScrollView.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

import UIKit

open class ITVScrollView: UIScrollView {
    
    fileprivate let tiledView = ITVTiledView()
    fileprivate let licenseView = ITVLicenceView()
    fileprivate var lastLevel: Int = -1
    
    fileprivate var url: String? {
        didSet {
            if url != nil {
                // TODO: implement decision here whether it is IIIF or Zoomify and move the logic in specific classes
                
                var block: ((Data?, URLResponse?, Error?) -> Void)? = nil
                if url!.lowercased().contains(IIIFImageDescriptor.propertyFile.lowercased()) {
                    // IIIF
                    print("ITV:: Downloading image as IIIF.")
                    block = {(data, response, error) in
                        if data != nil , let serialization = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) {
                            
                            let imageDescriptor = IIIFImageDescriptor(serialization as! [String : Any])
                            DispatchQueue.main.sync {
                                self.initWithDescriptor(imageDescriptor)
                            }
                        }
                    }
                }
                else if url!.lowercased().contains(ZoomifyImageDescriptor.propertyFile.lowercased()) {
                    // Zoomify
                    print("ITV:: Downloading image as Zoomify.")
                    block = {(data, response, error) in
                        if data != nil , let json = ZoomifyXMLParser().parse(data!) {
                            
                            let imageDescriptor = ZoomifyImageDescriptor(json, self.url!)
                            DispatchQueue.main.sync {
                                self.initWithDescriptor(imageDescriptor)
                            }
                        }
                    }
                }
                
                guard block != nil else {
                    // unsupported image API, should never happen here
                    return
                }
                
                URLSession.shared.dataTask(with: URL(string: url!)!, completionHandler:
                        block!).resume()
            }
        }
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
        delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(ITVScrollView.orientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        addSubview(tiledView)
        
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

    public func isZoomedOut() -> Bool {
        return self.zoomScale == 1.0
    }
    
    public func loadImage(_ imageUrl: String) {

        if imageUrl.lowercased().contains(IIIFImageDescriptor.propertyFile.lowercased()) ||
            imageUrl.lowercased().contains(ZoomifyImageDescriptor.propertyFile.lowercased()) {
            // address is prepared for loading
            self.url = imageUrl
        }
        else if imageUrl.lowercased().contains("/full/full/0/default.jpg") {
            // IIIF image, but url needs to be modified in order to download image information first
            self.url = imageUrl.replacingOccurrences(of: "full/full/0/default.jpg", with: IIIFImageDescriptor.propertyFile, options: .caseInsensitive, range: imageUrl.startIndex..<imageUrl.endIndex)
        }
        else if imageUrl.lowercased().contains("tilegroup") {
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
                print("Url \(imageUrl) does not support IIIF or Zoomify API.")
            }
        }
    }
    
    /// Synchronous test for url content download
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
    
    public func orientationDidChange() {
        
        guard let image = tiledView.image else {
            return
        }
        
        if isZoomedOut() {
            // resize tiledView only when not zoomed in
            resizeTiledView(image: image)
        }
        else {
            // else check only for need of reposition
            scrollViewDidZoom(self)
        }
    }
    
    fileprivate func initWithDescriptor(_ imageDescriptor: ITVImageDescriptor) {
        maximumZoomScale = imageDescriptor.getMaximumZoomScale()
        minimumZoomScale = imageDescriptor.getMinimumZoomScale(size: frame.size, viewScale: tiledView.contentScaleFactor)
        resizeTiledView(image: imageDescriptor)
        zoomScale = minimumZoomScale
        tiledView.image = imageDescriptor
        licenseView.imageDescriptor = imageDescriptor
    }
    
    fileprivate func resizeTiledView(image: ITVImageDescriptor) {
        let newSize = image.sizeToFit(size: frame.size, zoomScale: tiledView.contentScaleFactor)
        tiledView.frame = CGRect(origin: CGPoint.zero, size: newSize)
        scrollViewDidZoom(self)
    }
}

/// MARK: UIScrollViewDelegate implementation
extension ITVScrollView: UIScrollViewDelegate {
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // center the image as it becomes smaller than the size of the screen
        let boundsSize = bounds.size
        let f = tiledView.frame
        
        // center horizontally
        tiledView.frame.origin.x = (f.size.width < boundsSize.width) ? (boundsSize.width - f.size.width) / 2 : 0
        
        // center vertically
        tiledView.frame.origin.y = (f.size.height < boundsSize.height) ? (boundsSize.height - f.size.height) / 2 : 0
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        // redraw image by setting contentScaleFactor on tiledView
        let level = Int(round(log2(scale)))
        if level != lastLevel {
            tiledView.contentScaleFactor = pow(2.0, CGFloat(level))
            lastLevel = level
        }
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return tiledView
    }
}
