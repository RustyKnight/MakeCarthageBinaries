//
//  Carthage.swift
//  Files
//
//  Created by Shane Whitehead on 3/9/18.
//

import Foundation
import Files

public class Carthage {
  
  enum Error: Swift.Error {
    case Testing
  }
	
	private let path: Folder
	private let config: Configuration
	
	public init(path: Folder, configuration: Configuration) {
		self.path = path
		self.config = configuration
	}
	
	func runCarthage(arguments: [String]) throws {
		var command: [String] = []
		command.append(contentsOf: arguments)
		
		if config.isDebug {
			command.append("--configuration")
			command.append("Debug")
		}
		var failed = false
		var logs: String?
		log("***".lightBlack, "runCarthage\n\t  in \(path.path)\n\twith \(command)".lightBlack)
		_ = Executor.execute(currentDirectory: path.path, arguments: command) { data in
			guard var line = String(data: data, encoding: String.Encoding.utf8) else {
				log("***".red, "Error decoding data:")
				log("\t\(data)".magenta)
				return
			}
			
			line = line.trimmingCharacters(in: .whitespacesAndNewlines)
			guard line.count > 0 else {
				return
			}
			
			let filtered = line.replacingOccurrences(of: "***", with: "").trimmingCharacters(in: .whitespaces)
			
			if filtered.hasPrefix("Build Failed") || filtered.hasPrefix("Task failed") {
				failed = true
			}
			if filtered.hasPrefix("xcodebuild output can be found in") {
				logs = filtered.replacingOccurrences(of: "xcodebuild output can be found in", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
			}
			for part in line.split(separator: "\n") {
				log("[", part.trimmingCharacters(in: .whitespacesAndNewlines).lightBlack, "]")
			}
		}
		if failed {
			if let logs = logs {
				log("... Log files = \(logs)".lightBlack)
				Executor.execute(arguments: "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl", logs)
			}
			throw "Failed to build project"
		}
	}
	
	func buildDependencies() throws {		
		guard path.containsFile(named: "Cartfile") else {
			log("***".lightBlack, "\(path.name)".bold.lightBlack, "does not contain carthage depedencies".lightBlack)
			return
		}
    
    try updateCartFile()
		
		log("***".blue, "Build project", "\(path.name)".bold, "depedencies")
		let command: [String] = ["carthage", "bootstrap", "--no-build"] // They'll get built soon enough
		
		try runCarthage(arguments: command)
	}
	
	func buildCurrent() throws {
		log("***".blue, "Build project", "\(path.name)".bold)
		var command: [String] = ["carthage", "build", "--no-skip-current"]
//    if config.skipSimulators {
//      command.append("--skip-simulators")
//    }
		if config.isDebug {
			command.append("--configuration")
			command.append("Debug")
		}
		try runCarthage(arguments: command)
//		var failed = false
//		var logs: String?
//		_ = Executor.execute(currentDirectory: path.path, arguments: command) { data in
//			guard var line = String(data: data, encoding: String.Encoding.utf8) else {
//				log("***".red, "Error decoding data:")
//				log("\t\(data)".magenta)
//				return
//			}
//
//			line = line.trimmingCharacters(in: .whitespacesAndNewlines)
//			guard line.count > 0 else {
//				return
//			}
//
//			let filtered = line.replacingOccurrences(of: "***", with: "").trimmingCharacters(in: .whitespaces)
//
//			if filtered.hasPrefix("Build Failed") || filtered.hasPrefix("Task failed") {
//				failed = true
//			}
//			if filtered.hasPrefix("xcodebuild output can be found in") {
//				logs = filtered.replacingOccurrences(of: "xcodebuild output can be found in", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
//			}
//			for part in line.split(separator: "\n") {
//				log("[", part.trimmingCharacters(in: .whitespacesAndNewlines).lightBlack, "]")
//			}
//		}
//		if failed {
//			if let logs = logs {
//				log("... Log files = \(logs)".lightBlack)
//				Executor.execute(arguments: "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl", logs)
//			}
//			throw "Failed to build project"
//		}
	}
	
	public func build() throws {
		try buildDependencies()
		try buildCurrent()
	}
	
	func listFrameworks() throws -> [String] {
		let buildFolder = try path.subfolder(named: "Carthage").subfolder(named: "Build")
		var frameworks: Set<String> = Set()
		buildFolder.makeSubfolderSequence(recursive: true).forEach { (file) in
			var name = file.name
			guard let range = name.range(of: ".framework") else {
				return
			}
			name = String(name[name.startIndex..<range.lowerBound])
			frameworks.insert(name)
		}
		
		return frameworks.map { $0 }
	}
	
	public func archive() throws {
		log("***".blue, "Generate archive", "\(path.name)".bold)
		
		let arguments = ["carthage", "archive"]
		
		try runCarthage(arguments: arguments)
		
//		let names = try listFrameworks()
//		log("... including \(names.joined(separator: ", "))".lightBlack)
//		arguments.append(contentsOf: names)

//		_ = Executor.execute(currentDirectory: path.path, arguments: arguments) { data in
//			guard var line = String(data: data, encoding: String.Encoding.utf8) else {
//				log("***".red, "Error decoding data:")
//				log("\t\(data)".magenta)
//				return
//			}
//
//			line = line.trimmingCharacters(in: .whitespacesAndNewlines)
//			guard line.count > 0 else {
//				return
//			}
//			for part in line.split(separator: "\n") {
//				log("[", part.trimmingCharacters(in: .whitespacesAndNewlines).lightBlack, "]")
//			}
//		}
	}
  
  func updateCartFile() throws {
    guard let server = config.server else {
      log("*** No server specified, skip updating Cartfile".lightBlack)
      return
    }
    let cartFile = try path.file(atPath: "Cartfile")
    let contents = try cartFile.readAsString(encoding: String.Encoding.utf8)
    let lines = contents.split(separator: "\n").map { String($0) }

    log("***".yellow, "\(config.xcode.version)")
    log("***".yellow, "\(config.xcode.build)")
    
    let newBuild = "\(config.xcode.version)b\(config.xcode.build)"

    var modified = false
    var newLines: [String] = []
    let binaryLead = "binary \""
    for line in lines {
      if line.hasPrefix("binary \"\(server)/json") {
        guard !line.contains(newBuild) else { continue }
        let startIndex = line.index(line.startIndex, offsetBy: binaryLead.count)
        let endIndex = line.lastIndex(of: "\"")!
        let sufix = String(line.suffix(from: line.index(endIndex, offsetBy: 1)))
        let text = String(line[startIndex..<endIndex])
        guard let url = URL(string: text) else {
          log("***".yellow, "\(text) is not a valid URL")
          continue
        }
        var path = url.pathComponents
        guard path.count == 4 else {
          log("***".yellow, "\(text) does not contain the current number of path elements".magenta)
          continue
        }
        path[2] = newBuild
        
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
          log("***".yellow, "Could not build components from URL".magenta)
          continue
        }
        components.port = url.port
        components.path = path.joined(separator: "/")
        guard let newUrl = components.url else {
          log("***".yellow, "Could not create new URL".magenta)
          continue
        }
        let newText = newUrl.absoluteString.replacingOccurrences(of: "//json", with: "/json")
        newLines.append("binary \"\(newText)\"\(sufix)")
        modified = true
      } else {
        newLines.append(line)
      }
    }
    
    guard modified else { return }
    log("***".magenta, "Update Cartfile with new build version", "\(newBuild)".bold)
    try cartFile.write(string: String(newLines.joined(separator: "\n")), encoding: .utf8)
  }
	
}
