
//
//  ITVTiledView2.swift
//  Bond
//
//  Created by Jakub Fiser on 05/03/2018.
//

import UIKit
import Foundation


class ITVTiledView: UIView {

    internal var image: ITVImageDescriptor! {
        didSet {
            clearCache()
            backgroundImage.image = image
            backgroundLayer.image = image
            tiledLayer.image = image
        }
    }

    private let tiledLayer = ITVTiledLayer()
    private let backgroundLayer = ITVTiledLayer()
    private var backgroundImage: ITVBackgroundLayer!
    internal var itvDelegate: ITVScrollViewDelegate?
    private var level: Int {
        return Int(round(log2(contentScaleFactor)))
    }
    override var contentScaleFactor: CGFloat {
        didSet {
//            let level = self.level - 1
//            backgroundLayer.level = level
            tiledLayer.contentsScale = contentScaleFactor
            tiledLayer.setNeedsDisplay()
        }
    }

    /// use specific subclass of CALayer, that allows tile based image rendering
    override class var layerClass: AnyClass {
        return ITVBackgroundLayer.self
    }

    init() {
        super.init(frame: CGRect.zero)

        // provide transparent background for easy customization in storyboard
        backgroundColor = UIColor.clear

        backgroundImage = layer as! ITVBackgroundLayer
//        layer.addSublayer(backgroundLayer)
        layer.addSublayer(tiledLayer)
//        tiledLayer.isGeometryFlipped = true
//        tiledLayer.transform = CATransform3DMakeScale(1, -1, 1)
//        tiledLayer.transform = CATransform3DMakeTranslation(0, -1, 0)
//        tiledLayer.transform = CATransform3DConcat(CATransform3DMakeTranslation(0, 1, 0), CATransform3DMakeScale(1, -1, 1))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSublayers(of layer: CALayer) {
        backgroundLayer.frame = CGRect(origin: .zero, size: layer.bounds.size)
        tiledLayer.frame = backgroundLayer.frame
    }

    internal func refreshLayout() {
        backgroundImage.refreshLayout()
        backgroundLayer.refreshLayout()
        tiledLayer.refreshLayout()
    }

    internal func clearCache() {
        tiledLayer.clearCache()
    }
}


class ITVBackgroundLayer: CALayer {

    internal var image: ITVImageDescriptor! {
        didSet {
            refreshLayout()
            loadBackground()
        }
    }

    fileprivate var request: URLSessionDataTask?
    internal var itvDelegate: ITVScrollViewDelegate?

    func refreshLayout() {
        request?.cancel()
        guard contents != nil else { return }
        contents = nil
        delegate?.display?(self)
    }

    func loadBackground() {
        request?.cancel()
        if let url = image?.getBackgroundUrl() {
            request = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if data != nil, let image = UIImage.sd_image(with: data!) {
                    DispatchQueue.main.async {
                        self.contents = image.cgImage
                        self.delegate?.display?(self)
                    }
                }
            }
//            request?.resume()
        }
    }
}


class ITVTiledLayer: CATiledLayer {

    internal weak var itvDelegate: ITVScrollViewDelegate?
    internal var image: ITVImageDescriptor! {
        didSet {
            if image == nil {
                invalidateSession()
                clearCache()
                refreshLayout()
            } else {
//                if case 0..<image.tileSize.count = level {
//                    tileSize = image.tileSize[level]
//                } else {
//                    tileSize = CATiledLayer().tileSize
//                }
                levelsOfDetail = image.zoomScales.count
                // must be on main thread
                self.setNeedsDisplay()
            }
        }
    }

    fileprivate var session = URLSession(configuration: .default)
    fileprivate var imageCache = [String:UIImage]()
    fileprivate var level: Int = 1
    override var contentsScale: CGFloat {
        didSet {
            level = Int(round(log2(contentsScale)))
        }
    }


    open override class func fadeDuration() -> CFTimeInterval {
        return 0
    }

    func clearCache() {
        imageCache.removeAll()
    }

    func refreshLayout() {
        display()
    }

    fileprivate func invalidateSession() {
        session.invalidateAndCancel()
        session = URLSession(configuration: .default)
    }

    override func draw(in ctx: CGContext) {
//        var rect = ctx.boundingBoxOfClipPath
//        ctx.saveGState()
//        ctx.translateBy(x: 0, y: bounds.height)
//        ctx.translateBy(x: 0.0, y: rect.height)
//        ctx.scaleBy(x: 1, y: -1)
//        defer { ctx.restoreGState() }

//        rect = ctx.boundingBoxOfClipPath
        let rect = ctx.boundingBoxOfClipPath
        guard image != nil, !rect.isInfinite, !rect.isNull else {
            return
        }

        let viewScale = ctx.ctm.a
//        let column = Int(rect.midX / tileSize.width)
//        let row = Int(rect.midY / tileSize.height)
        let column = Int(rect.midX * viewScale / tileSize.width)
        let row = Int(rect.midY * viewScale / tileSize.height)
//        let row = Int(frame.height * viewScale / tileSize.height) - Int(rect.midY * viewScale / tileSize.height)

        let cacheKey = "\(level)-\(column)-\(row)"
        if let image = imageCache[cacheKey]?.cgImage {
//            print(cacheKey)
            ctx.saveGState()
            ctx.translateBy(x: 0.0, y: rect.height)
//            ctx.translateBy(x: 0.0, y: bounds.size.height)
            ctx.scaleBy(x: 1.0, y: -1.0)
            ctx.draw(image, in: ctx.boundingBoxOfClipPath)
//            ctx.draw(image, in: rect)
            ctx.restoreGState()
        } else if let requestURL = image.getUrl(x: column, y: row, level: level) {
//            print("ITVTiledLayer:: \(requestURL.absoluteString)")
            session.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                if (error as NSError?)?.code == NSURLErrorCancelled {
                    // task was cancelled
//                    print("ITVTiledLayer:: \(requestURL.absoluteString) cancelled.")
                    return
                } else if data != nil {
                    if let img = UIImage.sd_image(with: data) {
                        self.imageCache[cacheKey] = img
                        DispatchQueue.main.async {
                            self.setNeedsDisplay(rect)
                        }
                    } else {
//                        print("ITVTiledLayer:: \(requestURL.absoluteString) error image.")
                        let error = NSError.create(ITVError.imageDecoding, "Error decoding data from \(requestURL.absoluteString).")
                        self.itvDelegate?.errorDidOccur(error: error)
                    }
                } else {
                    var errorCode = ""
                    if let code = (response as? HTTPURLResponse)?.statusCode {
                        errorCode = "\(code) "
                    }
                    print("ITVTiledLayer:: \(requestURL.absoluteString) error \(error?.localizedDescription ?? "?")")
                    let error = NSError.create(ITVError.imageDownloading, "Error " + errorCode + "while downloading data from \(requestURL.absoluteString).")
                    self.itvDelegate?.errorDidOccur(error: error)
                }
            }).resume()
        } else if !(image is RawImageDescriptor) {
            // probably out of image's bounds
            print("ITVTiledLayer:: Request for non-existing tile at \(level):[\(column),\(row)].")
        }

        let displayTileBorders = true
        if displayTileBorders {
            ctx.setStrokeColor(UIColor.green.cgColor)
            ctx.setLineWidth(1)
            ctx.stroke(rect)
        }
    }
}
