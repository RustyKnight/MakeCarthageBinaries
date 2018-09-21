//
//  Installer.swift
//  Alamofire
//
//  Created by Shane Whitehead on 3/9/18.
//

import Foundation
import Files

public class Installer {
	
	private static let filePath: String = "/Volumes/build/caddyWWW/releases"
	private static let serverURL: URL = URL(string: "https://beam.carthage.com:8080/releases")!
	
	private let library: File
	private let name: String
	private let version: SemanticVersion
	private let config: Configuration
	
	init(library: File, name: String, version: SemanticVersion, configuration: Configuration) {
		self.library = library
		self.name = name
		self.version = version
		self.config = configuration
	}
	
	public static func install(library: File, name: String, version: SemanticVersion, configuration: Configuration) throws {
		guard let server = configuration.server else {
			log("***".yellow, "Web server property is undefined, can't upload library archive")
			return
		}
		
		let installer = Installer(library: library, name: name, version: version, configuration: configuration)
//		if FileManager.default.pathExists(atPath: Installer.filePath) {
//			try installer.usingFileSystem()
//		}
		
		try installer.uploadTo(server: server)
	}
	
	func uploadTo(server: String) throws {
		let data = try library.read()
		let text = data.base64EncodedString()
		
		let libraryName = config.name ?? library.parent!.name
		
		let upload = Uploadable(libraryVersion: version.description,
														name: libraryName,
														xcodeVersion: config.xcode.version,
														xcodeBuild: config.xcode.build,
														data: text)

		let encoder = JSONEncoder()
		let jsonData = try encoder.encode(upload)
		guard let jsonText = String(data: jsonData, encoding: .utf8) else {
			throw "Failed to encode request"
		}
		
		guard let url = URL(string: server) else {
			throw "Invalid URL"
		}
		var request = URLRequest(url: url)
		request.setValue("application/zip", forHTTPHeaderField: "Content-Type")
		request.httpMethod = "POST"
		request.httpBody = jsonData
		
		let semaphore = DispatchSemaphore(value: 0)
		var failed = true
		
		let timer = Timer()
		timer.isRunning = true
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			defer {
				semaphore.signal()
			}
			if let error = error {
				log("***".red, "\(self.library.name)".bold, "failed to upload - \(error)".bold)
				return
			}
			guard let response = response as? HTTPURLResponse else {
				log("***".red, "\(self.library.name)".bold, "failed to upload - invalid response".bold)
				return
			}
			guard response.statusCode == 200 else {
				log("***".red, "\(self.library.name)".bold, "failed to upload - server responded with \(response.statusCode)".bold)
				return
			}
			failed = false
			log("***".green, "\(self.library.name)".bold, "was uploaded successfully")
		}
		task.resume()
		log("***".green, "Uploading", "\(self.library.name)".bold, "...")
		semaphore.wait()
		
		timer.isRunning = false
		guard !failed else {
			return
		}
		log("***".green, "Took", "\(durationFormatter.string(from: timer.duration)!)".bold, "to upload", "\(self.library.name)".bold)
	}
	
	func usingFileSystem() throws {
		// Really, really, really need to know if this should be done via
		// scp
		let releasePath =	try Folder(path: Installer.filePath)
			.createSubfolderIfNeeded(withName: name)
			.createSubfolderIfNeeded(withName: version.description)
		
		log("***".green, "Copy", "\(library.name)".bold, "\n      to", "\(releasePath.path)".bold)
		
		let data = try library.read()
		try releasePath.createFileIfNeeded(withName: library.name, contents: data)

		log("***".green, "Update binary project specification...")

		var json: [String: Any] = [:]
		let releaseFolder = try Folder(path: Installer.filePath)
		
		let fileName = "\(name)-\(config.xcode.stamp).json"
		if releaseFolder.existsFile(named: fileName) {
			json = try loadJSON(from: try releaseFolder.file(named: fileName))
		}
		
		let versionText = version.description
		let releaseURL = Installer.serverURL
			.appendingPathComponent(name)
			.appendingPathComponent(versionText)
			.appendingPathComponent(library.name)
		
		json[versionText] = releaseURL.absoluteString
		try save(json: json, toFileNamed: fileName, at: releaseFolder)
	}
	
	func loadJSON(from: File) throws -> [String: Any] {
		let data = try from.read()
		let jsonObj = try JSONSerialization.jsonObject(with: data, options: [])
		guard let json = jsonObj as? [String: Any] else {
			throw "Invalid Carthage Binrary Project Specification"
		}
		return json
	}
	
	func save(json: [String: Any], toFileNamed named: String, at folder: Folder) throws {		
		let file = try folder.createFileIfNeeded(withName: named)
		
		let jsonData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
		var text = String(data: jsonData, encoding: .utf8)!
		text = text.replacingOccurrences(of: "\\/", with: "/")
		
		let data = text.data(using: .utf8)!
		try file.write(data: data)
	}
}

struct Uploadable: Codable {
	var libraryVersion: String
	var name: String
	var xcodeVersion: String
	var xcodeBuild: String
	var data: String
}
