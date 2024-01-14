//
//  Configuration.swift
//  Files
//
//  Created by Shane Whitehead on 3/9/18.
//

import Foundation
import ArgumentParser

public class Configuration {
    public var isCurrent = false
    public var isDebug = false
    public var skipBuildIfExists = false
    public var xcode: Xcode
    public var overrideVersion: String? = nil
    public var name: String? = nil
    public var noSkipSimulators: Bool = false
    public var useXcodeFrameworks: Bool = false
    public var tag: String = "default"
    
    public var server: String? = nil
    
    init(xcode: Xcode) {
        self.xcode = xcode
    }
    
    public static func build(from args: [String]) throws -> Configuration {
        let xCode = try xcodeVersion()
        let config = Configuration(xcode: xCode)
        config.xcode = xCode
        
        let arguments = Array(args.dropFirst())
        let parser = ArgumentParser(usage: "{<options>}", overview: "Builds and archives Xcode projects with Carthage as Carthage Binary Releases")
        let server = parser.add(option: "--server", kind: String.self, usage: "(Optional) The server URL to upload library archives to")
        let current = parser.add(option: "--current", kind: Bool.self, usage: "(Optional) Build the current directory only (default scans a builds all sub directories)")
        let skip = parser.add(option: "--skip", kind: Bool.self, usage: "(Optional) Skip building/archive if existing artifacts exist (default will delete them)")
        let overrideVersion = parser.add(option: "--overrideVersion", kind: String.self, usage: "(Optional) Overrides the version of the library (default looks up the version from the GIT repo) - must be in {major}.{minor}.{patch} format")
        let name = parser.add(option: "--name", kind: String.self, usage: "(Optional) Overrides the name of Carthage Binary Release (default will use the name of the directory)")
        let debugBuild = parser.add(option: "--debugBuild", kind: Bool.self, usage: "(Optional) Build the project with the 'Debug' configuration")
        let noSkipSims = parser.add(option: "--noSkipSimulators", kind: Bool.self, usage: "(Optional) Don't skip building binaries for simulators (where supported by target platform), default will skip")
        let useXcodeFrameworks = parser.add(option: "--useXcodeFrameworks", kind: Bool.self, usage: "(Optional) Use the newer Xcodeframe[S] structure (Xcode 12+) (default is to use the original format)")
        let tag = parser.add(option: "--tag", kind: String.self, usage: "(Optional) Tag to be used when uploading the archive - allows for a level of customisation for each version of the archive (like suppporting different Xcode binary formats)")
        
        let parsedArguments = try parser.parse(arguments)
        
        config.server = parsedArguments.get(server) ?? nil
        config.isCurrent = parsedArguments.get(current) ?? false
        config.skipBuildIfExists = parsedArguments.get(skip) ?? false
        config.isDebug = parsedArguments.get(debugBuild) ?? false
        config.overrideVersion = parsedArguments.get(overrideVersion) ?? nil
        config.name = parsedArguments.get(name) ?? nil
        config.noSkipSimulators = parsedArguments.get(noSkipSims) ?? false
        config.useXcodeFrameworks = parsedArguments.get(useXcodeFrameworks) ?? false
        config.tag = parsedArguments.get(tag) ?? "default"
        
        return config
    }
}

public class Xcode {
    public var version: String = ""
    public var build: String = ""
    
    public var stamp: String {
        return "Xcode-\(version)-\(build)"
    }
}

private func xcodeVersion() throws -> Xcode {
    var version: String?
    var build: String?
    Executor.execute(arguments: "xcodebuild", "-version") { (data) in
        guard var line = String(data: data, encoding: String.Encoding.utf8) else {
            log("***".red, "Error decoding data:")
            log("\t\(data)".magenta)
            return
        }
        
        line = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard line.count > 0 else {
            return
        }
        for part in line.split(separator: "\n") {
            if part.hasPrefix("Xcode") {
                version = part.split(separator: " ")[1].trimmingCharacters(in: .whitespacesAndNewlines)
            } else if part.hasPrefix("Build") {
                build = part.split(separator: " ")[2].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }
    guard let ver = version, let bld = build else {
        throw "Could not determine Xcode version"
    }
    let xCode = Xcode()
    xCode.build = bld
    xCode.version = ver
    return xCode
}
