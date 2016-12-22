//
//  IIIFImageDescriptor.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

/**
 Class representing all the information about specific image. This class conforms to IIIFImage API of version 2.1.
 */
class IIIFImageDescriptor {
    
    static let propertyFile = "info.json"
    fileprivate static let version1Context = "http://library.stanford.edu/iiif/image-api/1.1/context.json"
    fileprivate static let version2Context = "http://iiif.io/api/image/2/context.json"
    
    static func versionedDescriptor(_ json: [String:Any]) -> ITVImageDescriptor? {
        let context = json["@context"] as! String
        if context == version1Context {
            return IIIFImageDescriptorV1(json)
        }
        else if context == version2Context {
            return IIIFImageDescriptorV2(json)
        }
        else {
            // TODO: return empty struct with error implementing ITVImageDescriptor protocol
            let _error = NSError(domain: Constants.TAG, code: 100, userInfo: [Constants.USERINFO_KEY:"Unsupported IIIF Image version."])
            return nil
        }
    }
    
    fileprivate init() {}
}
