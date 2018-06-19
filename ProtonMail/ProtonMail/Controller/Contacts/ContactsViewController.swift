//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import UIKit
import Contacts
import CoreData

class ContactsViewController: ProtonMailViewController, ViewModelProtocol {
    
    fileprivate let kContactCellIdentifier: String = "ContactCell"
    fileprivate let kProtonMailImage: UIImage      = UIImage(named: "encrypted_main")!
    //
    fileprivate let kContactDetailsSugue : String  = "toContactDetailsSegue";
    fileprivate let kAddContactSugue : String      = "toAddContact"
    
    fileprivate let kSegueToImportView : String    = "toImportContacts"
    
    fileprivate var searchString : String = ""
 
    // Mark: - view model
    fileprivate var viewModel : ContactsViewModel!
    
    // MARK: - View Outlets
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    // MARK: - Private attributes
    fileprivate var refreshControl: UIRefreshControl!
    fileprivate var searchController : UISearchController!
    
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchViewConstraint: NSLayoutConstraint!
    
    fileprivate var addBarButtonItem : UIBarButtonItem!
    fileprivate var moreBarButtonItem : UIBarButtonItem!
    
    func inactiveViewModel() {
    }
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactsViewModel
    }
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = LocalString._contacts_title
        tableView.register(UINib(nibName: "ContactsTableViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: kContactCellIdentifier)
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = LocalString._general_search_placeholder
        searchController.searchBar.setValue(LocalString._general_cancel_button,
                                            forKey:"_cancelButtonText")
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.searchController.hidesNavigationBarDuringPresentation = true
        self.searchController.automaticallyAdjustsScrollViewInsets = true
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchBar.keyboardType = .default
        self.searchController.searchBar.autocapitalizationType = .none
        self.searchController.searchBar.isTranslucent = false
        self.searchController.searchBar.tintColor = .white
        self.searchController.searchBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background
        self.searchController.searchBar.backgroundColor = .clear
        
        refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = UIColor(RRGGBB: UInt(0xDADEE8))
        refreshControl.addTarget(self,
                                 action: #selector(fireFetch),
                                 for: UIControlEvents.valueChanged)
        
        tableView.addSubview(self.refreshControl)
        tableView.dataSource = self
        tableView.delegate = self
        
        refreshControl.tintColor = UIColor.gray
        refreshControl.tintColorDidChange()
        
        if #available(iOS 11.0, *) {
            self.searchViewConstraint.constant = 0.0
            self.searchView.isHidden = true
            self.navigationController?.navigationBar.prefersLargeTitles = false
            self.navigationItem.largeTitleDisplayMode = .never
            self.navigationItem.hidesSearchBarWhenScrolling = false
            self.navigationItem.searchController = self.searchController
        } else {
            self.searchViewConstraint.constant = self.searchController.searchBar.frame.height
            self.navigationController?.navigationBar.setBackgroundImage(UIImage.imageWithColor(UIColor.ProtonMail.Nav_Bar_Background), for: UIBarPosition.any, barMetrics: UIBarMetrics.default)
            self.navigationController?.navigationBar.shadowImage = UIImage.imageWithColor(UIColor.ProtonMail.Nav_Bar_Background)
            
            self.refreshControl.backgroundColor = .white
            
            self.searchView.backgroundColor = UIColor.ProtonMail.Nav_Bar_Background
            self.searchView.addSubview(self.searchController.searchBar)
            self.searchController.searchBar.contactSearchSetup(textfieldBG: UIColor.init(hexColorCode: "#82829C"), placeholderColor: UIColor.init(hexColorCode: "#BBBBC9"), textColor: .white)
        }
        self.definesPresentationContext = true;
        self.extendedLayoutIncludesOpaqueBars = true
        self.automaticallyAdjustsScrollViewInsets = false
        self.tableView.noSeparatorsBelowFooter()
        self.tableView.sectionIndexColor = UIColor.ProtonMail.Blue_85B1DE
        
        let back = UIBarButtonItem(title: LocalString._general_back_action,
                                   style: UIBarButtonItemStyle.plain,
                                   target: nil,
                                   action: nil)
        self.navigationItem.backBarButtonItem = back
        
        if self.addBarButtonItem == nil {
            self.addBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .add,
                                                         target: self,
                                                         action: #selector(self.addContactTapped))
        }
        var rightButtons: [UIBarButtonItem] = [self.addBarButtonItem]
        if #available(iOS 9.0, *) {
            if (self.moreBarButtonItem == nil) {
                self.moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "top_more"),
                                                         style: UIBarButtonItemStyle.plain,
                                                         target: self,
                                                         action: #selector(self.moreButtonTapped))
            }
            rightButtons.append(self.moreBarButtonItem)
        }

        self.navigationItem.setRightBarButtonItems(rightButtons, animated: true)
        
        //get all contacts
        self.viewModel.setupFetchedResults(delaget: self)
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.setEditing(false, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.setupTimer(true)
        NotificationCenter.default.addKeyboardObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewModel.stopTimer()
        NotificationCenter.default.removeKeyboardObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == kContactDetailsSugue) {
            let contactDetailsViewController = segue.destination as! ContactDetailViewController
            let contact = sender as? Contact
            sharedVMService.contactDetailsViewModel(contactDetailsViewController, contact: contact!)
        } else if (segue.identifier == kAddContactSugue) {
            let addContactViewController = segue.destination.childViewControllers[0] as! ContactEditViewController
            sharedVMService.contactAddViewModel(addContactViewController)
        } else if (segue.identifier == "toCompose") {
        } else if segue.identifier == kSegueToImportView{
            let popup = segue.destination as! ContactImportViewController
            self.setPresentationStyleForSelfController(self, presentingController: popup, style: .overFullScreen)
        }
    }
    
    @objc internal func fireFetch() {
        self.viewModel.fetchContacts { (contacts: [Contact]?, error: NSError?) in
            if let error = error as NSError? {
                PMLog.D(" error: \(error)")
                let alertController = error.alertController()
                alertController.addOKAction()
                self.present(alertController, animated: true, completion: nil)
            }
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    @objc internal func addContactTapped() {
        self.performSegue(withIdentifier: kAddContactSugue, sender: self)
    }
    
    @available(iOS 9.0, *)
    @objc internal func moreButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Upload Contacts",  comment: "Action"), style: .default, handler: { (action) -> Void in
            self.navigationController?.popViewController(animated: true)
            
            let alertController = UIAlertController(title: LocalString._contacts_title,
                                                    message: LocalString._upload_ios_contacts_to_protonmail,
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: LocalString._general_confirm_action,
                                                    style: .default, handler: { (action) -> Void in
                self.performSegue(withIdentifier: self.kSegueToImportView, sender: self)
            }))
            alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }))
    
        alertController.popoverPresentationController?.barButtonItem = moreBarButtonItem
        alertController.popoverPresentationController?.sourceRect = self.view.frame
        self.present(alertController, animated: true, completion: nil)
    }
}

//Search part
extension ContactsViewController: UISearchBarDelegate, UISearchResultsUpdating {
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        self.searchString = searchController.searchBar.text ?? "";
        self.viewModel.search(text: self.searchString)
        self.tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        refreshControl.endRefreshing()
        refreshControl.removeFromSuperview()
        self.viewModel.set(searching: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        tableView.addSubview(refreshControl)
        self.viewModel.set(searching: false)
    }
}

// MARK: - UITableViewDataSource
extension ContactsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.sectionCount()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.rowCount(section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ContactsTableViewCell = tableView.dequeueReusableCell(withIdentifier: kContactCellIdentifier,
                                                                        for: indexPath) as! ContactsTableViewCell
        if let contact = self.viewModel.item(index: indexPath) {
            cell.config(name: contact.name,
                        email: contact.getDisplayEmails(),
                        highlight: self.searchString)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ContactsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteClosure = { (action: UITableViewRowAction!, indexPath: IndexPath!) -> Void in
            if let contact = self.viewModel.item(index: indexPath) {
                let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                alertController.addAction(UIAlertAction(title: LocalString._general_cancel_button, style: .cancel, handler: nil))
                alertController.addAction(UIAlertAction(title: LocalString._delete_contact,
                                                        style: .destructive, handler: { (action) -> Void in
                    ActivityIndicatorHelper.showActivityIndicator(at: self.view)
                    self.viewModel.delete(contactID: contact.contactID, complete: { (error) in
                        ActivityIndicatorHelper.hideActivityIndicator(at: self.view)
                        if let err = error {
                            err.alert(at : self.view)
                        }
                    })
                }))
                
                alertController.popoverPresentationController?.sourceView = self.view
                alertController.popoverPresentationController?.sourceRect = self.view.frame
                self.present(alertController, animated: true, completion: nil)
            }
        }
        
        let deleteAction = UITableViewRowAction(style: .default,
                                                title: LocalString._general_delete_action,
                                                handler: deleteClosure)
        return [deleteAction]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let contact = self.viewModel.item(index: indexPath) {
            self.performSegue(withIdentifier: kContactDetailsSugue, sender: contact)
        }
    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        //TODO:: add this later the full size index
//        - (void)viewDidLoad
//            {
//                [super viewDidLoad];
//                self.indexArray = @[@"{search}", @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J",@"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];
//            }
//
//            - (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
//        {
//            NSString *letter = [self.indexArray objectAtIndex:index];
//            NSUInteger sectionIndex = [[self.fetchedResultsController sectionIndexTitles] indexOfObject:letter];
//            while (sectionIndex > [self.indexArray count]) {
//                if (index <= 0) {
//                    sectionIndex = 0;
//                    break;
//                }
//                sectionIndex = [self tableView:tableView sectionForSectionIndexTitle:title atIndex:index - 1];
//            }
//
//            return sectionIndex;
//            }
//
//            - (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
//        {
//            return self.indexArray;
//        }
        return self.viewModel.sectionForSectionIndexTitle(title: title, atIndex: index)
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.viewModel.sectionIndexTitle()
    }
    
}

// MARK: - NSNotificationCenterKeyboardObserverProtocol
extension ContactsViewController: NSNotificationCenterKeyboardObserverProtocol {
    func keyboardWillHideNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        UIView.animate(withDuration: keyboardInfo.duration,
                       delay: 0,
                       options: keyboardInfo.animationOption, animations: { () -> Void in
            self.tableViewBottomConstraint.constant = 0
        }, completion: nil)
    }
    
    func keyboardWillShowNotification(_ notification: Notification) {
        let keyboardInfo = notification.keyboardInfo
        let info: NSDictionary = notification.userInfo! as NSDictionary
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            UIView.animate(withDuration: keyboardInfo.duration,
                           delay: 0,
                           options: keyboardInfo.animationOption, animations: { () -> Void in
                self.tableViewBottomConstraint.constant = keyboardSize.height
            }, completion: nil)
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension ContactsViewController : NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch(type) {
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
            }
        case .insert:
            if let newIndexPath = newIndexPath {
                PMLog.D("Section: \(newIndexPath.section) Row: \(newIndexPath.row) ")
                tableView.insertRows(at: [newIndexPath], with: UITableViewRowAnimation.fade)
            }
        case .update:
            if let indexPath = indexPath {
                if let cell = tableView.cellForRow(at: indexPath) as? ContactsTableViewCell {
                    if let contact = self.viewModel.item(index: indexPath) {
                        cell.contactEmailLabel.text = contact.getDisplayEmails()
                        cell.contactNameLabel.text = contact.name
                    }
                }
            }
            break
        default:
            return
        }
    }
}

