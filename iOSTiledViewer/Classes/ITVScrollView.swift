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
    
    fileprivate var url: String? {
        didSet {
            if url != nil {
                // TODO: implement decision here whether it is IIIF or Zoomify and move the logic in specific classes
                
                let baseUrl = url!.replacingOccurrences(of: "/full/full/0/default.jpg", with: "")
                URLSession.shared.dataTask(with: URL(string: "\(baseUrl)/info.json")!, completionHandler: { (data, response, error) in
                    
                    if data != nil , let serialization = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) {
                        
                        let imageDescriptor = IIIFImageDescriptor(serialization as! [String : Any])
                        self.maximumZoomScale = CGFloat(imageDescriptor.tiles?.scaleFactors?.last != nil ? imageDescriptor.tiles!.scaleFactors!.last! : 1)
                        DispatchQueue.main.async {
                            self.resizeTiledView(image: imageDescriptor)
                            self.tiledView.image = imageDescriptor
                        }
                    }
                }).resume()
            }
        }
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
        delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(ITVScrollView.orientationDidChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        addSubview(tiledView)
    }

    public func isZoomedOut() -> Bool {
        return self.zoomScale == 1.0
    }
    
    public func loadImage(_ imageUrl: String) {
        self.url = imageUrl
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
    
    fileprivate func resizeTiledView(image: IIIFImageDescriptor) {
        var newSize = sizeAspectFit(width: image.width, height: image.height)
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
        tiledView.contentScaleFactor = scale
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return tiledView
    }
}
