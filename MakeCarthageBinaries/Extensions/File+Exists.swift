//
//  File+Exists.swift
//  Files
//
//  Created by Shane Whitehead on 3/9/18.
//

import Foundation
import Files

extension File {
    
    var exists: Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
}
