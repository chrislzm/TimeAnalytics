//
//  TATableViewController.swift
//  Time Analytics
//
//  Heavily modified version of CoreDataViewControler originally created by Fernando Rodríguez Romero on 2/22/16
//  Implements a tableView linked with a Core Data fetched results controller.
//
//  Abstract class. Has three concrete subclasses: TAPlaceTableViewController, TACommuteTableViewController, TAActivityTableViewController
//
//  Copyright © 2017 Chris Leung. All rights reserved.
//

import UIKit
import CoreData

// MARK: - CoreDataTableViewController: UITableViewController

class TATableViewController: TAViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Properties
    
    let activityIndicatoryXY = 0
    let activityIndicatorPixelSize = 20
    let activityIndicatorStyle = UIActivityIndicatorViewStyle.gray
    
    let tableSectionHeaderHeight = CGFloat(30)
    let tableSectionFontSize = CGFloat(13)
    let tableSectionFontWeight = UIFontWeightBold
    let tableSectionFontColor = UIColor.black
    let tableSectionBackgroundColor = UIColor.groupTableViewBackground
    
    let tabBarImageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
    
    var tableView:UITableView! = nil
    var activityIndicatorView:UIActivityIndicatorView! // Shown in navbar when updating data in the background
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self
            executeSearch()
            tableView.reloadData()
        }
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup table style
        tableView.separatorStyle = .none

        // Remove titles from Tabbar
        for tabBarItem in (tabBarController?.tabBar.items)!
        {
            tabBarItem.title = ""
            tabBarItem.imageInsets = tabBarImageInsets
        }
        
        // Setup activity view in navigation bar
        activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: activityIndicatorStyle)
        activityIndicatorView.frame = CGRect(x: activityIndicatoryXY, y: activityIndicatoryXY, width: activityIndicatorPixelSize, height: activityIndicatorPixelSize)
        let activityIndicatorBarButtonItem = UIBarButtonItem(customView: activityIndicatorView)
        navigationItem.setLeftBarButton(activityIndicatorBarButtonItem, animated: false)
        
        // Observe notifications so we can animate activityView when downloading/processing
        NotificationCenter.default.addObserver(self, selector: #selector(TATableViewController.willDownloadData(_:)), name: Notification.Name("willDownloadMovesData"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(TATableViewController.didCompleteUpdate(_:)), name: Notification.Name("didCompleteAllUpdates"), object: nil)
    }
    
    // MARK: View Methods
    
    func showSettingsMenu() {
        let controller = storyboard?.instantiateViewController(withIdentifier: "TASettingsView") as! TASettingsViewController
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func startActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicatorView.startAnimating()
        }
    }
    
    func stopActivityIndicator() {
        DispatchQueue.main.async {
            self.activityIndicatorView.stopAnimating()
        }
    }
    
    // MARK: Notification Observers
    
    func willDownloadData(_ notification:Notification) {
        startActivityIndicator()
    }
    
    func didCompleteUpdate(_ notification:Notification) {
        stopActivityIndicator()
    }
    
    // Error handling -- Fail gracefully by stopping the activity indicator. We don't need to let the user know here, since this error is most likely from a background auto-update that will attempt again after a short time. If the user initiates a refresh manually in the settings panel, it will display an alert to notify the user of any errors.
    override func downloadMovesDataError(_ notification:Notification) {
        super.downloadMovesDataError(notification)
        handleError()
    }
    
    override func movesDataParsingError(_ notification:Notification) {
        super.movesDataParsingError(notification)
        handleError()
    }
    
    override func healthDataReadError(_ notification:Notification) {
        super.healthDataReadError(notification)
        handleError()
    }
    
    func handleError() {
        stopActivityIndicator()
    }
}

// MARK: - CoreDataTableViewController (Subclass Must Implement)

extension TATableViewController {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("This method MUST be implemented by a subclass of CoreDataTableViewController")
    }
}

// MARK: - CoreDataTableViewController (Table Data Source)

extension TATableViewController {

    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let fc = fetchedResultsController {
            return (fc.sections?.count)!
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle: String?
        if let sectionIdentifier = fetchedResultsController!.sections?[section].name {
            if let numericSection = Int(sectionIdentifier) {
                // Parse the numericSection into its year/month/day components.
                let year = numericSection / 10000
                let month = (numericSection / 100) % 100
                let day = numericSection % 100
                
                // Reconstruct the date from these components.
                var components = DateComponents()
                components.calendar = Calendar.current
                components.day = day
                components.month = month
                components.year = year
                
                let today = Date()
                let calendar = Calendar.current
                let todayDay = calendar.component(.day, from: today)
                let todayMonth = calendar.component(.month, from: today)
                let todayYear = calendar.component(.year, from: today)
                
                if month==todayMonth,year==todayYear {
                    if day==todayDay {
                        return "Today"
                    } else if day == todayDay-1 {
                        return "Yesterday"
                    }
                }
                
                // Set the section title with this date
                if let date = components.date {
                    
                    sectionTitle = DateFormatter.localizedString(from: date, dateStyle: .full, timeStyle: .none)
                }
            }
        }
        
        return sectionTitle
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.section(forSectionIndexTitle: title, at: index)
        } else {
            return 0
        }
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = tableSectionBackgroundColor
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = tableSectionFontColor
        header.textLabel?.font = UIFont.systemFont(ofSize: tableSectionFontSize, weight: tableSectionFontWeight)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableSectionHeaderHeight
    }
}

// MARK: - CoreDataTableViewController (Fetches)

extension TATableViewController {
    
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                fatalError(("Error while trying to perform a search: \n\(e)\n\(String(describing: fetchedResultsController))"))
            }
        }
    }
}

// MARK: - CoreDataTableViewController: NSFetchedResultsControllerDelegate

extension TATableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        let set = IndexSet(integer: sectionIndex)
        switch (type) {
        case .insert:
            tableView.insertSections(set, with: .fade)
        case .delete:
            tableView.deleteSections(set, with: .fade)
        default:
            // irrelevant in our case
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
