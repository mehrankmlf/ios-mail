//
//  QueueDefind.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/1/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


struct QueueConstant {
    
    #if Enterprise
    static let queueIdentifer = "com.protonmail.persistentQueue"
    #else
    static let queueIdentifer = "ch.protonmail.persistentQueue"
    #endif
    
    enum QueueTypes{
        
    }
}