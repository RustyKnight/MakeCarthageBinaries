//
//  Folder+Exists.swift
//  Files
//
//  Created by Shane Whitehead on 3/9/18.
//

import Foundation
import Files

extension Folder {
    var exists: Bool {
        return FileManager.default.pathExists(atPath: path)
    }
    
    func existsFile(named: String) -> Bool {
        guard (try? file(named: named)) != nil else {
            return false
        }
        return true
    }
}
