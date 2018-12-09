//
//  LabelsDataService.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/13/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation
import CoreData
import Groot

let sharedLabelsDataService = LabelsDataService()

enum LabelFetchType : Int {
    case all = 0
    case label = 1
    case folder = 2
    case contactGroup = 3
}

class LabelsDataService {
    
    func cleanUp() {
        Label.deleteAll(inContext: sharedCoreDataService.backgroundManagedObjectContext)
    }
    
    /**
     Fetch all contact groups using API call
     
     No email list is included in this fetching operation
     
     - Parameter type: type 1 is for message labels, type 2 is for contact groups
     */
    func fetchLabels(type: Int = 1) {
        let eventAPI = GetLabelsRequest(type: type)
        eventAPI.call() {
            task, response, hasError in
            
            if response == nil {
                //TODO:: error
            } else if let labels = response?.labels {
                //save
                let context = sharedCoreDataService.backgroundManagedObjectContext
                context.performAndWait() {
                    do {
                        let labels_out = try GRTJSONSerialization.objects(withEntityName: Label.Attributes.entityName, fromJSONArray: labels, in: context)
                        let error = context.saveUpstreamIfNeeded()
                        if error == nil {
                            if labels_out.count != labels.count {
                               PMLog.D("error: label insertions failed partially!")
                            }
                        } else {
                            //TODO:: error
                            PMLog.D("error: \(String(describing: error))")
                        }
                    } catch let ex as NSError {
                        PMLog.D("error: \(ex)")
                    }
                }
            } else {
                //TODO:: error
            }
        }
    }
    
    func getAllLabels(of type : LabelFetchType) -> [Label] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Label.Attributes.entityName)
        switch type {
        case .all:
            fetchRequest.predicate = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1)", "(?!^\\d+$)^.+$", Label.Attributes.type)
        case .folder:
            fetchRequest.predicate = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == true) ", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.exclusive)
        case .label:
            fetchRequest.predicate = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == false) ", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.exclusive)
        case .contactGroup:
            // in contact group searching, predicate must be consistent with this one
            fetchRequest.predicate = NSPredicate(format: "(%K == 2)", Label.Attributes.type)
        }
        
        let context = sharedCoreDataService.mainManagedObjectContext
        do {
            let results = try context.fetch(fetchRequest)
            if let results = results as? [Label] {
                return results
            } else {
                // TODO: handle error
                PMLog.D("COnversion to Label error")
            }
        } catch {
            PMLog.D("Get context failed")
        }
        
        return []
    }
    
    func fetchedResultsController(_ type : LabelFetchType) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let moc = sharedCoreDataService.mainManagedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Label.Attributes.entityName)
        
        switch type {
        case .all:
            fetchRequest.predicate = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1)", "(?!^\\d+$)^.+$", Label.Attributes.type)
        case .folder:
            fetchRequest.predicate = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == true) ", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.exclusive)
        case .label:
            fetchRequest.predicate = NSPredicate(format: "(labelID MATCHES %@) AND (%K == 1) AND (%K == false) ", "(?!^\\d+$)^.+$", Label.Attributes.type, Label.Attributes.exclusive)
        case .contactGroup:
            // in contact group searching, predicate must be consistent with this one
            fetchRequest.predicate = NSPredicate(format: "(%K == 2)", Label.Attributes.type)
        }
        
        if type != .contactGroup {
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: Label.Attributes.order, ascending: true)]
        } else {
            let strComp = NSSortDescriptor(key: Label.Attributes.name,
                                           ascending: true,
                                           selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
            fetchRequest.sortDescriptors = [strComp]
        }
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func addNewLabel(_ response : [String : Any]?) {
        if let label = response {
            let context = sharedCoreDataService.backgroundManagedObjectContext
            context.performAndWait() {
                do {
                    try GRTJSONSerialization.object(withEntityName: Label.Attributes.entityName, fromJSONDictionary: label, in: context)
                    if let error = context.saveUpstreamIfNeeded() {
                        PMLog.D("addNewLabel error: \(error)")
                    }
                } catch let ex as NSError {
                    PMLog.D("addNewLabel error: \(ex)")
                }
            }
        }
    }
}
