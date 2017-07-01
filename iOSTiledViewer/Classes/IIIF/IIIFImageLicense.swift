//
//  IIIFImageLicense.swift
//  Pods
//
//  Created by Jakub Fiser on 13/10/2016.
//
//

class IIIFImageLicense: NSObject {
    
    /**
     Can be:
     single String value
     array of String values
     dictionary of associated languages
     
     Array and dictionary can be combined.
     */
    var attribution: String? {
        get {
            
            // If there is no language associated value, return all values (single value or array)
            if self.attribution_dict == nil {
                return attribution_array?.joined(separator: "\n") ?? attribution_single
            }
            
            // Otherwise determine user's language or set a default one
            let lang: String
            if let value = Locale.current.languageCode {
                lang = value
            }
            else {
                lang = "en"
            }
            
            // If there is value associated to specified language
            if let value = self.attribution_dict![lang] {
                return value
            }
                // If there is not, but there are values with no language associated
            else if self.attribution_array != nil {
                return self.attribution_array!.joined(separator: "\n")
            }
            
            // Otherwise choose some random language and return its values.
            let randomLang = self.attribution_dict!.keys.first!
            return self.attribution_dict![randomLang]
        }
    }
    var license: String?
    var logo: String?
    
    fileprivate var attribution_dict: [String: String]?
    fileprivate var attribution_array: [String]?
    fileprivate var attribution_single: String?
    
    init(_ json: [String:Any]) {
        
        if let attributionObj = json["attribution"] {
            if let value = attributionObj as? String {
                self.attribution_single = value
            }
            else if let arraySimple = attributionObj as? [String] {
                self.attribution_array = arraySimple
            }
            else if let arrayDict = attributionObj as? [[String:String]] {
                self.attribution_dict = [String:String]()
                for item in arrayDict {
                    let key = item["@language"]!
                    let value = item["@value"]!
                    self.attribution_dict![key] = value
                }
            }
            else if let arrayComplex = attributionObj as? [Any] {
                self.attribution_dict = [String:String]()
                self.attribution_array = [String]()
                for item in arrayComplex {
                    if let value = item as? String {
                        self.attribution_array!.append(value)
                    }
                    else if let dict = item as? [String:String] {
                        let key = dict["@language"]!
                        let value = dict["@value"]!
                        self.attribution_dict![key] = value
                    }
                }
            }
        }
        
        if let logoObj = json["logo"] {
            if let value = logoObj as? String {
                self.logo = value
            }
            else if let dict = logoObj as? [String: Any] ,
                let value = dict["@id"] as? String {
                self.logo = value
            }
        }
        
        if let licenseObj = json["license"] {
            if let value = licenseObj as? String {
                self.license = value
            }
            else if let values = licenseObj as? [String] {
                self.license = values.joined(separator: "\n")
            }
        }
    }
}
