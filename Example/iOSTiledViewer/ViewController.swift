//
//  ViewController.swift
//  iOSTiledViewer
//
//  Created by Jakub Fiser on 10/13/2016.
//  Copyright (c) 2016 Jakub Fiser. All rights reserved.
//

import UIKit
import iOSTiledViewer

class ViewController: UIViewController, ITVErrorDelegate {

    var urlString: String!
    @IBOutlet weak var scrollView: ITVScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        scrollView.errorDelegate = self
        scrollView.loadImage(urlString)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // Simple example of handling errors from ITV
    // parameter not relevant for now, since this method is being called only for 1 error currently
    func errorDidOccur(error: Error) {
        let alert = UIAlertController(title: "Oops", message: "Error loading image.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
            _ = self.navigationController?.popViewController(animated: true)
        }))
        present(alert, animated: true, completion: nil)
    }
}

