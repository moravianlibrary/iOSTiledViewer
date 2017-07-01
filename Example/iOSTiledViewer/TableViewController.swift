//
//  TableViewController.swift
//  iOSTiledViewer
//
//  Created by Jakub Fiser on 07/11/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    fileprivate let url = URL(string: "https://drive.google.com/uc?id=0B1TdqMC3wGUJXzA4YU1RVDFHZEk")!
    fileprivate var dataImages: [String]? {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // dynamic table view cells height
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 40
        
        // initial data load
        refreshList()
        
        // pull to refresh, enabled in storyboard
        refreshControl?.addTarget(self, action: #selector(TableViewController.refreshList), for: .valueChanged)
    }

    // pull to refresh behavior
    func refreshList() {
        URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
            if data != nil, let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) {
                DispatchQueue.main.async {
                    self.dataImages = json as? [String]
                }
            }
            self.refreshControl?.endRefreshing()
        }).resume()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataImages?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        cell.textLabel?.text = dataImages?[indexPath.row]
        cell.textLabel?.numberOfLines = 0

        return cell
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showImage", let link = (sender as? UITableViewCell)?.textLabel?.text {
            let detail = segue.destination as! ViewController
            detail.urlString = link
        }
    }

}
