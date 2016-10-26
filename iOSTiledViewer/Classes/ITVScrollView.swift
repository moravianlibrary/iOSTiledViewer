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
    fileprivate var lastLevel: Int = -1
    
    fileprivate var url: String? {
        didSet {
            if url != nil {
                // TODO: implement decision here whether it is IIIF or Zoomify and move the logic in specific classes
                
                var block: ((Data?, URLResponse?, Error?) -> Void)? = nil
                if url!.lowercased().contains(IIIFImageDescriptor.propertyFile.lowercased()) {
                    // IIIF
                    print("Downloading image as IIIF.")
                    block = {(data, response, error) in
                        if data != nil , let serialization = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) {
                            
                            let imageDescriptor = IIIFImageDescriptor(serialization as! [String : Any])
                            self.maximumZoomScale = CGFloat(imageDescriptor.tiles?.scaleFactors?.last != nil ? imageDescriptor.tiles!.scaleFactors!.last! : 1)
                            DispatchQueue.main.async {
                                self.resizeTiledView(image: imageDescriptor)
                                self.tiledView.image = imageDescriptor
                            }
                        }
                    }
                }
                else if url!.lowercased().contains(ZoomifyImageDescriptor.propertyFile.lowercased()) {
                    // Zoomify
                    print("Downloading image as Zoomify.")
                    block = {(data, response, error) in
                        if data != nil , let json = ZoomifyXMLParser().parse(data!) {
                            
                            let imageDescriptor = ZoomifyImageDescriptor(json, self.url!)
                            self.maximumZoomScale = CGFloat(powf(2, Float(imageDescriptor.depth)))
                            DispatchQueue.main.async {
                                self.resizeTiledView(image: imageDescriptor)
                                self.tiledView.image = imageDescriptor
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
        setZoomScale(1.0, animated: false)
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
    
    fileprivate func resizeTiledView(image: ITVImageDescriptor) {
        let newSize = sizeAspectFit(width: image.width, height: image.height)
        tiledView.frame = CGRect(origin: CGPoint.zero, size: newSize)
        scrollViewDidZoom(self)
    }
    
    fileprivate func sizeAspectFit(width: Int, height: Int) -> CGSize {
        return sizeAspectFit(width: CGFloat(width), height: CGFloat(height))
    }
    
    fileprivate func sizeAspectFit(width: CGFloat, height: CGFloat) -> CGSize {
        let imageSize = CGSize(width: width, height: height)
        var aspectFitSize = frame.size
        let mW = aspectFitSize.width / imageSize.width
        let mH = aspectFitSize.height / imageSize.height
        if mH <= mW {
            aspectFitSize.width = mH * imageSize.width
        }
        else if mW <= mH {
            aspectFitSize.height = mW * imageSize.height
        }
        return aspectFitSize
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
        // redraw image
//        tiledView.contentScaleFactor = scale
        
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
