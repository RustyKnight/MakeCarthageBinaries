//
//  FileManager+PathExists.swift
//  Files
//
//  Created by Shane Whitehead on 3/9/18.
//

import Foundation

extension FileManager {
    
    func pathExists(atPath path: String) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
}
