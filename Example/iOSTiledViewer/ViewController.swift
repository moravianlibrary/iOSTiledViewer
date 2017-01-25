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

    // table view stuff
    var numberOfLines = 2
    var pickerIndex: IndexPath?
    var pickerType: String?
    let titles = ["Quality","Format"]
    
    var urlString: String!
    @IBOutlet weak var scrollView: ITVScrollView!
    @IBOutlet weak var optionsView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        scrollView.itvDelegate = self
        scrollView.loadImage(urlString, api: .Unknown)
        
        closeOptions()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        scrollView.didRecieveMemoryWarning()
    }
    
    func openOptions() {
        optionsView.reloadData()
        navigationItem.hidesBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(ViewController.closeOptions))
        view.bringSubview(toFront: optionsView)
        optionsView.isHidden = false
    }
    
    func closeOptions() {
        navigationItem.hidesBackButton = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Options", style: .plain, target: self, action: #selector(ViewController.openOptions))
        optionsView.isHidden = true
        numberOfLines = 2
        pickerIndex = nil
        pickerType = nil
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
    
    func errorDidOccur(error: NSError) {
//        let alert = UIAlertController(title: "Oops", message: error.userInfo["message"] as? String, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
//            alert.dismiss(animated: true, completion: nil)
//        }))
//        present(alert, animated: true, completion: nil)
    }
}

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return numberOfLines
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let isPicker = indexPath == pickerIndex
        let id = isPicker ? "cell2" : "cell1"
        let cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath)
        
        if isPicker {
            let picker = cell.contentView.subviews.first as! UIPickerView
            let valueIndex = IndexPath(row: indexPath.row-1, section: indexPath.section)
            let value = tableView.cellForRow(at: valueIndex)!.detailTextLabel!.text!
            let array = pickerType == titles[0] ? scrollView.imageQualities : scrollView.imageFormats
            let selectionIndex = array!.index(of: value)
            picker.selectRow(selectionIndex != nil ? selectionIndex! : 0, inComponent: 0, animated: false)
            picker.reloadAllComponents()
        } else {
            cell.textLabel?.text = titles[indexPath.row]
            let value = indexPath.row == 0 ? scrollView.currentQuality : scrollView.currentFormat
            cell.detailTextLabel?.text = value != nil ? value : "none"
        }
        
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if pickerIndex != nil {
            tableView.beginUpdates()
            tableView.deleteRows(at: [pickerIndex!], with: .automatic)
            numberOfLines -= 1
            pickerIndex = nil
            tableView.endUpdates()
            
            pickerType = nil
        } else {
            let cell = tableView.cellForRow(at: indexPath)
            let array = indexPath.row == 0 ? scrollView.imageQualities : scrollView.imageFormats
            guard cell?.detailTextLabel?.text != "none", array != nil, array!.count > 1 else {
                return
            }
            
            pickerType = titles[indexPath.row]
            pickerIndex = IndexPath(row: indexPath.row+1, section: indexPath.section)
            
            tableView.beginUpdates()
            tableView.insertRows(at: [pickerIndex!], with: UITableViewRowAnimation.automatic)
            numberOfLines += 1
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath == pickerIndex ? 110 : 40
    }
}

extension ViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        let array = pickerType == titles[0] ? scrollView.imageQualities : scrollView.imageFormats
        return array != nil ? array!.count : 0
    }
}

extension ViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let array = pickerType == titles[0] ? scrollView.imageQualities : scrollView.imageFormats
        return array![row]
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 26
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerType == titles[0] {
            let value = scrollView.imageQualities![row]
            scrollView.currentQuality = value
            optionsView.cellForRow(at: IndexPath(row: 0, section: 0))?.detailTextLabel?.text = value
        } else {
            let value = scrollView.imageFormats![row]
            scrollView.currentFormat = value
            optionsView.cellForRow(at: IndexPath(row: 1, section: 0))?.detailTextLabel?.text = value
        }
    }
}
