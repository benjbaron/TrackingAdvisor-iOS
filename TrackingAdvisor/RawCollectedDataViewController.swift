//
//  RawCollectedDataViewController.swift
//  TrackingAdvisor
//
//  Created by Benjamin BARON on 11/6/17.
//  Copyright © 2017 Benjamin BARON. All rights reserved.
//

import UIKit

class RawCollectedDataViewController: UITableViewController {
    
    // MARK: - Properties
    var files:[URL]!
    var deleteFileIndexPath: IndexPath? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        files = FileService.shared.listFiles()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return files?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "collectedDataCell", for: indexPath)
        cell.textLabel?.text = files?[indexPath.row].deletingPathExtension().lastPathComponent ?? ""
        return cell
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteFileIndexPath = indexPath
            // confirm the deletion
            let fileToDelete = files[indexPath.row]
            confirmDelete(file: fileToDelete)
        }
    }
    
    func confirmDelete(file: URL) {
        let filename = file.deletingPathExtension().lastPathComponent
        let alert = UIAlertController(title: "Delete File", message: "Are you sure you want to permanently delete \(filename)?", preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: handleDeleteFile)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: cancelDeleteFile)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        // Support presentation in iPad
        alert.popoverPresentationController?.sourceView = self.view
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleDeleteFile(alertAction: UIAlertAction!){
        if let indexPath = deleteFileIndexPath {
            tableView.beginUpdates()
            // Delete the file from the file system
            FileService.shared.delete(file: files[indexPath.row])
            // Remove the file from the array
            files.remove(at: indexPath.row)
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
            deleteFileIndexPath = nil
            tableView.endUpdates()
        }
        
    }

    func cancelDeleteFile(alertAction: UIAlertAction!) {
        deleteFileIndexPath = nil
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFileContent",
            let destination = segue.destination as? RawCollectedDataTextViewController, let fileIndex = tableView.indexPathForSelectedRow?.row {
            destination.filename = files?[fileIndex].deletingPathExtension().lastPathComponent ?? ""
            destination.filecontent = FileService.shared.read(from: (files?[fileIndex])!)
            destination.file = files?[fileIndex]
        }
    }
}
