//
//  BugReportCache.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 10/19/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation



let cachedBugReport = BugReportCache(shared: UserDefaults.standard)

final class BugReportCache : SharedCacheBase {
    
    fileprivate struct Key {
        static let lastBugReport = "BugReportCache_LastBugReport"
    }
    
    open var cachedBug: String! {
        get {
            return getShared().string(forKey: Key.lastBugReport) ?? ""
        }
        set {
            getShared().setValue(newValue, forKey: Key.lastBugReport)
            getShared().synchronize()
        }
    }
    
    open func clear() {
        getShared().removeObject(forKey: Key.lastBugReport)
        getShared().synchronize()
    }
}
