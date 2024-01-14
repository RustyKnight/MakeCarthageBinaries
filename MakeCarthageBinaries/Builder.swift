//
//  Builder.swift
//  Files
//
//  Created by Shane Whitehead on 3/9/18.
//

import Foundation
import Files

public class Builder {
    
    private let path: Folder
    private let config: Configuration
    
    public init(path: Folder, configuration config: Configuration) {
        self.path = path
        self.config = config
    }
    
    public var containsFrameworkZipFile: Bool {
        do {
            return try frameworkZipFiles().count > 0
        } catch {
        }
        return false
    }
    
    public var containsCarthageArtifacts: Bool {
        do {
            return try carthageArtifacts().count > 0
        } catch {
        }
        return false
    }
    
    public func build() throws -> File {
        if !config.skipBuildIfExists {
            try preMake()
        }
        
        let timer = Timer()
        timer.isRunning = true
        
        let carthage = Carthage(path: path, configuration: config)
        
        if !config.skipBuildIfExists || !containsCarthageArtifacts {
            try carthage.build()
        }
        if !config.skipBuildIfExists || !containsFrameworkZipFile {
            try carthage.archive()
        }
        
        guard containsCarthageArtifacts else {
            throw "Failed to build project binaries for \(path.name)"
        }
        guard containsFrameworkZipFile else {
            throw "Failed to generate binary archives for \(path.name)"
        }
        
        //		for archive in try frameworkZipFiles() {
        //			guard !archive.name.contains("Xcode") else {
        //				continue
        //			}
        //			let name = archive.name
        //			// Split the name apart
        //			var nameParts = name.split(separator: ".").map({String($0)})
        //			// Inject the xcode version
        //			nameParts.insert(config.xcode.stamp, at: 1)
        //			// Put the name back together
        //			let newName = nameParts.joined(separator: ".")
        //			// Append it to the parent path
        //			try archive.rename(to: newName)
        //		}
        
        timer.isRunning = false
        log("***".green, "Took", "\(durationFormatter.string(from: timer.duration)!)".bold, "to build/archive", "\(path.name)".bold)
        
        return try frameworkZipFiles()[0]
    }
    
    private func preMake() throws {
        try removeZipFiles()
        try removeCarthageArtifacts()
    }
    
    private func removeZipFiles() throws {
        try remove(try frameworkZipFiles())
    }
    
    private func removeCarthageArtifacts() throws {
        try remove(try carthageArtifacts())
        if path.containsFile(named: "Cartfile.resolved") {
            let file = try path.file(named: "Cartfile.resolved")
            try remove([file])
        }
    }
    
    
    private func frameworkZipFiles() throws -> [File] {
        let matches = path.files.filter( { $0.name.lowercased().hasSuffix(".framework.zip") } )
        return matches
    }
    
    private func carthageArtifacts() throws -> [Folder] {
        var folders: [Folder] = []
        
        if path.containsSubfolder(named: "Carthage/Build"){
            folders.append(try Folder(path: path.path + "Carthage/Build"))
        }
        if path.containsSubfolder(named: "Carthage/Checkouts"){
            folders.append(try Folder(path: path.path + "Carthage/Checkouts"))
        }
        
        return folders
        
        //		let matches = path.subfolders.filter { (folder) -> Bool in
        //			guard folder.name.lowercased() == "carthage" else {
        //				return false
        //			}
        //			return folder.containsSubfolder(named: "Build")
        //		}
        //		return matches
    }
    
    private func remove(_ files: [File]) throws {
        for file in files {
            log("***".red, "Delete")
            log("\t\(file.path)".white)
            try file.delete()
        }
    }
    
    private func remove(_ folders: [Folder]) throws {
        for folder in folders {
            log("***".red, "Delete")
            log("\t\(folder.path)".white)
            try folder.delete()
        }
    }
    
}
