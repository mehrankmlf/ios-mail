//
//  ContactGroupEditViewController.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/16.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit
import PromiseKit

/**
 The design for now is no auto-saving
 */
class ContactGroupEditViewController: ProtonMailViewController, ViewModelProtocol {
    let kToContactGroupSelectColorSegue = "toContactGroupSelectColorSegue"
    let kToContactGroupSelectEmailSegue = "toContactGroupSelectEmailSegue"
    
    let kContactGroupEditCellIdentifier = "ContactGroupEditCell"
    
    @IBOutlet weak var contactGroupNameLabel: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var navigationBarItem: UINavigationItem!
    @IBOutlet weak var tableView: UITableView!
    var viewModel: ContactGroupEditViewModel!
    var activeText: UIResponder? = nil
    
    func setViewModel(_ vm: Any) {
        viewModel = vm as! ContactGroupEditViewModel
    }
    
    func inactiveViewModel() {}
    
    @IBAction func cancelItem(_ sender: UIBarButtonItem) {
        // becuase the object might not be deinit right away
        // we need to restore the data
        dismissKeyboard()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UINib(nibName: "ContactGroupEditViewCell", bundle: Bundle.main),
                           forCellReuseIdentifier: kContactGroupEditCellIdentifier)
        
        viewModel.delegate = self
        contactGroupNameLabel.delegate = self
        
        loadDataIntoView()
        tableView.noSeparatorsBelowFooter()
    }
    
    func loadDataIntoView() {
        navigationBarItem.title = viewModel.getViewTitle()
        contactGroupNameLabel.text = viewModel.getName()
        
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func dismissKeyboard() {
        if let t = activeText {
            t.resignFirstResponder()
            activeText = nil
        }
    }
    
    @IBAction func saveAction(_ sender: UIBarButtonItem) {
        // TODO: spinning while saving... (blocking)
        
        dismissKeyboard()
        firstly {
            viewModel.saveDetail()
            }.done {
                (_) -> Void in
                
                self.dismiss(animated: true, completion: nil)
            }.catch {
                error in
                
                let alert = UIAlertController(title: "Can not save contact group",
                                              message: error.localizedDescription,
                                              preferredStyle: .alert)
                alert.addOKAction()
                self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kToContactGroupSelectColorSegue {
            let contactGroupSelectColorViewController = segue.destination as! ContactGroupSelectColorViewController
            
            let refreshHandler = {
                (newColor: String?) -> Void in
                self.viewModel.setColor(newColor: newColor)
            }
            sharedVMService.contactGroupSelectColorViewModel(
                contactGroupSelectColorViewController,
                                                             currentColor: viewModel.getColor(),
                                                             refreshHandler: refreshHandler)
        } else if segue.identifier == kToContactGroupSelectEmailSegue {
            let refreshHandler = {
                (emailIDs: NSSet) -> Void in
                
                self.viewModel.setEmails(emails: emailIDs)
            }
            
            let contactGroupSelectEmailViewController = segue.destination as! ContactGroupSelectEmailViewController
            let data = sender as! ContactGroupEditViewController
            sharedVMService.contactGroupSelectEmailViewModel(contactGroupSelectEmailViewController,
                                                             selectedEmails: data.viewModel.getEmails(),
                                                             refreshHandler: refreshHandler)
        } else {
            PMLog.D("No such segue")
            fatalError("No such segue")
        }
    }
}

extension ContactGroupEditViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.getTotalSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getTotalRows(for: section)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.getSectionTitle(for: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.getCellType(at: indexPath) {
        case .selectColor:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactGroupColorCell", for: indexPath)
            return cell
        case .manageContact:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactGroupManageCell", for: indexPath)
            cell.textLabel?.text = "Manage Addresses"
            return cell
        case .email:
            let cell = tableView.dequeueReusableCell(withIdentifier: kContactGroupEditCellIdentifier,
                                                     for: indexPath) as! ContactGroupEditViewCell
            
            let (name, email) = viewModel.getEmail(at: indexPath)
            cell.config(name: name, email: email)
            return cell
        case .deleteGroup:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactGroupDeleteCell", for: indexPath)
            return cell
        case .error:
            fatalError("This is a bug")
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch viewModel.getCellType(at: indexPath) {
        case .selectColor:
            // display color
            cell.detailTextLabel?.backgroundColor = UIColor(hexString: viewModel.getColor(),
                                                            alpha: 1.0)
        case .error:
            fatalError("This is a bug")
        default:
            return
        }
    }
}

extension ContactGroupEditViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch viewModel.getCellType(at: indexPath) {
        case .selectColor:
            self.performSegue(withIdentifier: kToContactGroupSelectColorSegue, sender: self)
        case .manageContact:
            self.performSegue(withIdentifier: kToContactGroupSelectEmailSegue, sender: self)
        case .email:
            print("email actions")
        case .deleteGroup:
            viewModel.deleteContactGroup()
            self.dismiss(animated: true, completion: nil)
        case .error:
            fatalError("This is a bug")
        }
    }
}

extension ContactGroupEditViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeText = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        contactGroupNameLabel.text = textField.text
        viewModel.setName(name: textField.text ?? "")
        
        activeText = nil
    }
}

extension ContactGroupEditViewController: ContactGroupEditViewControllerDelegate
{
    func update() {
        loadDataIntoView()
    }
}
