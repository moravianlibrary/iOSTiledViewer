//
//  ViewController.swift
//  iOSTiledViewer
//
//  Created by Jakub Fiser on 10/13/2016.
//  Copyright (c) 2016 Jakub Fiser. All rights reserved.
//

import UIKit
import iOSTiledViewer

class ViewController: UIViewController {

    var urlString: String!
    @IBOutlet weak var scrollView: ITVScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        scrollView.itvDelegate = self
        scrollView.loadImage(urlString)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: ITVScrollViewDelegate {
    
    func didFinishLoading(error: NSError?) {
        if error != nil {
            let alert = UIAlertController(title: "Oops", message: error!.userInfo["message"] as? String, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                _ = self.navigationController?.popViewController(animated: true)
            }))
            present(alert, animated: true, completion: nil)
        }
        else {
            // hide loading indicator for example
        }
    }
}
