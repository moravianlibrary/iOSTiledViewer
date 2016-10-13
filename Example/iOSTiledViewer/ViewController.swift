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

    @IBOutlet weak var scrollView: ITVScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        scrollView.loadImage("https://iiif.ucd.ie/loris/ivrla:29953/full/full/0/default.jpg")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

