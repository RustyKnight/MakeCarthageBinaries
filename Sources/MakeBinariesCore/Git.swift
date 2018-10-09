//
//  Git.swift
//  Files
//
//  Created by Shane Whitehead on 3/9/18.
//

import Foundation
import Files

public class Git {
	private let path: Folder
	
	public init(path: Folder) {
		self.path = path
	}
	
	public func versions() -> [SemanticVersion] {
		var versions: [SemanticVersion] = []
//		git describe --tags
		let command: [String] = ["git", "tag"]
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
			for part in line.split(separator: "\n") {
				guard let version = SemanticVersion.parse(from: String(part)) else {
          log("***".yellow, "\(part) is not a Semantic Version".lightBlack)
					continue
				}
        log(">>> Found Tag \(version)".lightBlack)
				versions.append(version)
			}
		}
		return versions.sorted().reversed()
	}
	
}

public struct SemanticVersion: Comparable, Equatable, CustomStringConvertible {
	
	public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
		guard lhs.major == rhs.major else {
			return lhs.major < rhs.major
		}
		guard lhs.minor == rhs.minor else {
			return lhs.minor < rhs.minor
		}
		guard lhs.patch == rhs.patch else {
			return lhs.patch < rhs.patch
		}
		return false // is equal
	}
	
	public static func > (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
		guard lhs.major == rhs.major else {
			return lhs.major > rhs.major
		}
		guard lhs.minor == rhs.minor else {
			return lhs.minor > rhs.minor
		}
		guard lhs.patch == rhs.patch else {
			return lhs.patch > rhs.patch
		}
		return false // is equal
	}
	
	public static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
		guard lhs.major == rhs.major, lhs.minor == rhs.minor, lhs.patch == rhs.patch else {
			return false
		}
		return true
	}

	
	public let major: Int
	public let minor: Int
	public let patch: Int
	
	public init(major: Int, minor: Int, patch: Int) {
		self.major = major
		self.minor = minor
		self.patch = patch
	}
	
	public static func parse(from: String) -> SemanticVersion? {
		var raw = from.lowercased()
		if raw.hasPrefix("v") {
			raw = String(raw.dropFirst())
		}
		let parts = raw.split(separator: ".")
		guard parts.count == 3 else {
			return nil
		}
		
		guard let major = Int(parts[0]), let minor = Int(parts[1]), let patch = Int(parts[2]) else {
			return nil
		}
		
		return SemanticVersion(major: major,
													 minor: minor,
													 patch: patch)
	}
	
	public var description: String {
		return "\(major).\(minor).\(patch)"
	}

}
