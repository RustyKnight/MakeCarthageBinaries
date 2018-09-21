//
//  Carthage.swift
//  Files
//
//  Created by Shane Whitehead on 3/9/18.
//

import Foundation
import Files

public class Carthage {
	
	private let path: Folder
	private let config: Configuration
	
	public init(path: Folder, configuration: Configuration) {
		self.path = path
		self.config = configuration
	}
	
	public func build() throws {
		log("***".blue, "Build project", "\(path.name)".bold)
		var command: [String] = ["carthage", "build", "--no-skip-current"]
		if config.isDebug {
			command.append("--configuration")
			command.append("Debug")
		}
    var failed = false
    var logs: String?
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
		
		var arguments = ["carthage", "archive"]
		
		let names = try listFrameworks()
		log("... including \(names.joined(separator: ", "))".lightBlack)
		arguments.append(contentsOf: names)

		_ = Executor.execute(currentDirectory: path.path, arguments: arguments) { data in
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
				log("[", part.trimmingCharacters(in: .whitespacesAndNewlines).lightBlack, "]")
			}
		}
	}
	
}
