//
//  NSFetchedResultsControllerExtension.swift
//  ProtonMail
//
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

import Foundation
import CoreData

extension NSFetchedResultsController {
    
    @objc func numberOfRows(in section: Int) -> Int {
        if let sectionInfo = sections?[section] {
            return sectionInfo.numberOfObjects
        } else {
            return 0
        }
    }
    
    @objc func numberOfSections() -> Int {
        if let n = sections?.count {
            return n
        }
        return 0
    }
}