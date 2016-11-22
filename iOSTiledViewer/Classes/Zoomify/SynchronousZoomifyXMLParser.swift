//
//  SynchronousZoomifyXMLParser
//  Pods
//
//  Created by Jakub Fiser on 21/10/2016.
//
//

import UIKit

class SynchronousZoomifyXMLParser: NSObject, XMLParserDelegate {

    fileprivate let parserSemaphore = DispatchSemaphore(value: 0)
    fileprivate var json: [String:String]?
    
    func parse(_ data: Data) -> [String:String]? {
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        parserSemaphore.wait()
        
        return json
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if elementName == "IMAGE_PROPERTIES" {
            self.json = attributeDict
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        parserSemaphore.signal()
    }
}
