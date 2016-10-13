//
//  ITVScrollView.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

import UIKit

open class ITVScrollView: UIScrollView {
    
    // internal to make it visible in extensions
    internal let tiledView = ITVTiledView()
    
    internal var url: String? {
        didSet {
            if url != nil {
                // TODO: implement decision here whether it is IIIF or Zoomify and move the logic in specific classes
                
                let baseUrl = url!.replacingOccurrences(of: "/full/full/0/default.jpg", with: "")
                URLSession.shared.dataTask(with: URL(string: "\(baseUrl)/info.json")!, completionHandler: { (data, response, error) in
                    
                    if data != nil , let serialization = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) {
                        
                        let imageDescriptor = IIIFImageDescriptor(serialization as! [String : Any])
                        DispatchQueue.main.async {
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
        maximumZoomScale = 10 // TODO: will be based on image info
        
        // We want to have full control of constraints
        tiledView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(tiledView)
        addConstraints([
            NSLayoutConstraint(item: tiledView.superview!, attribute: .leading, relatedBy: .equal, toItem: tiledView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tiledView.superview!, attribute: .trailing, relatedBy: .equal, toItem: tiledView, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tiledView.superview!, attribute: .top, relatedBy: .equal, toItem: tiledView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tiledView.superview!, attribute: .bottom, relatedBy: .equal, toItem: tiledView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: tiledView, attribute: .width, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: tiledView, attribute: .height, multiplier: 1, constant: 0)
            ])
    }

}

/// MARK: UIScrollViewDelegate implementation
extension ITVScrollView: UIScrollViewDelegate {
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // center the image as it becomes smaller than the size of the screen
        let boundsSize = scrollView.bounds.size
        var frameToCenter = tiledView.frame
        
        // center horizontally
        frameToCenter.origin.x = (frameToCenter.size.width < boundsSize.width) ? (boundsSize.width - frameToCenter.size.width) / 2 : 0
        
        // center vertically
        frameToCenter.origin.y = (frameToCenter.size.height < boundsSize.height) ? (boundsSize.height - frameToCenter.size.height) / 2 : 0
        
        tiledView.frame = frameToCenter
        self.setNeedsDisplay(scrollView.convert(scrollView.bounds, to: tiledView))
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        // redraw image
        tiledView.contentScaleFactor = scale
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return tiledView
    }
}

/// MARK: ITVProtocol implementation
extension ITVScrollView: ITVDelegate {
    
    public func isZoomedOut() -> Bool {
        return self.zoomScale == 1.0
    }
    
    public func loadImage(_ imageUrl: String) {
        self.url = imageUrl
    }
}
