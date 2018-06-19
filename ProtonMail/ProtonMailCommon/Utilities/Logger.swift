//
//  NSLogExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/4/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


public class PMLog {
    
    public static func D(nstring message: NSString, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column)
    {
        #if DEBUG
            print("\(file) : \(function) : \(line) : \(column) ↓ \r\n\(message)")
        #endif
    }
    
    public static func D(_ message: String, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column)
    {
        #if DEBUG
            print("\(file) : \(function) : \(line) : \(column) ↓ \r\n\(message)")
        #endif
    }
    
    public static func D(any message: Any, file: String = #function, function: String = #file, line: Int = #line, column: Int = #column )
    {
        #if DEBUG
            print("\(file) : \(function) : \(line) : \(column) ↓ \r\n\(message)")
        #endif
    }
    
}