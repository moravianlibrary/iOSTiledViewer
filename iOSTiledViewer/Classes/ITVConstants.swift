//
//  ITVConstants.swift
//  Pods
//
//  Created by Jakub Fiser on 14/11/2016.
//
//

internal struct Constants {
    static let TAG = "iOSTiledViewer"
    static let ERROR_DOMAIN = "cz.mzk.iosTiledViewer"
    static let USERINFO_KEY = "message"
    static let SCREEN_SCALE = UIScreen.main.nativeScale
}


internal extension NSError {
    static func create(_ code: ITVError, _ message: String) -> NSError {
        return NSError(domain: Constants.ERROR_DOMAIN, code: code.rawValue, userInfo: [Constants.USERINFO_KEY: message])
    }
}
