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
		let uploader = FileUploader()
		try uploader.upload(library: library, name: name, version: version, configuration: config, server: server)
	}
	
//
//	func uploadTo(server: String) throws {
////		let data = try library.read()
////		let text = data.base64EncodedString()
//
//		let semaphore = DispatchSemaphore(value: 0)
//		var failed = true
//
//		DispatchQueue.global(qos: .userInitiated).async {
//			do {
//				try self.performUpload(to: server)
//				failed = false
//			} catch let error {
//				log("***".red, "\(error)")
//			}
//			semaphore.signal()
//		}
//
//		log("*** Waiting for upload to complete...".lightBlack)
//		semaphore.wait()
//
//		guard failed else {
//			return
//		}
//		throw "Upload faild"
//	}
//
//	func performUpload(to server: String) throws {
//		log("***".green, "Preparing to upload", "\(self.library.name)".bold, "...")
//		let semaphore = DispatchSemaphore(value: 0)
//		let timer = Timer()
//		timer.isRunning = true
//
//		log("... read library archive".lightBlack)
//		let data = try library.read()
//
//		let libraryName = config.name ?? library.parent!.name
//
//		guard let url = URL(string: server) else {
//			throw "Invalid URL"
//		}
//		log("... make request".lightBlack)
//		var request = URLRequest(url: url)
//		request.httpMethod = "POST"
//		let param = [
//			"name": libraryName,
//			"version": version.description,
//			"xcodeVersion": config.xcode.version,
//			"xcodeBuild": config.xcode.build
//		]
//
//		let boundary = "Boundary-\(UUID().uuidString)"
//		request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//		log("... create body".lightBlack)
//		let body = try createBody(parameters: param, boundary: boundary, data: data)
//		request.httpBody = body
//
//		//		let encoder = JSONEncoder()
//		//		let jsonData = try encoder.encode(upload)
//		//		guard let jsonText = String(data: jsonData, encoding: .utf8) else {
//		//			throw "Failed to encode request"
//		//		}
//		//
//		//		guard let url = URL(string: server) else {
//		//			throw "Invalid URL"
//		//		}
//		//		var request = URLRequest(url: url)
//		//		request.httpMethod = "POST"
//		//		request.httpBody = jsonData
//		//
//		//
//		//		let timer = Timer()
//		//		timer.isRunning = true
//
//		let URLSessionConfig = URLSessionConfiguration.default
//		let session = URLSession(configuration: URLSessionConfig, delegate: self, delegateQueue: OperationQueue.main)
//
//		var failed = true
//		log("... create task".lightBlack)
//		let task = URLSession.shared.dataTask(with: request) { data, response, error in
//			defer {
//				log("... signal".lightBlack)
//				semaphore.signal()
//			}
//			log("... Error check".lightBlack)
//			if let error = error {
//				log("***".red, "\(self.library.name)".bold, "failed to upload - \(error)".bold)
//				return
//			}
//			log("... Response cheeck".lightBlack)
//			guard let response = response as? HTTPURLResponse else {
//				log("***".red, "\(self.library.name)".bold, "failed to upload - invalid response".bold)
//				return
//			}
//			log("... Response status code check".lightBlack)
//			guard response.statusCode == 200 else {
//				log("***".red, "\(self.library.name)".bold, "failed to upload - server responded with \(response.statusCode)".bold)
//				return
//			}
//			log("... Completed".lightBlack)
//			failed = false
//			log("***".green, "\(self.library.name)".bold, "was uploaded successfully")
//		}
//		log("... resume task".lightBlack)
//		task.resume()
//		log("***".green, "Uploading", "\(self.library.name)".bold, "...")
//		semaphore.wait()
//
//		timer.isRunning = false
//		guard !failed else {
//			return
//		}
//		log("***".green, "Took", "\(durationFormatter.string(from: timer.duration)!)".bold, "to upload", "\(self.library.name)".bold)
//	}
//
//	func createBody(parameters: [String: String], boundary: String, data: Data) throws -> Data {
//		var body = Data()
//		let prefix = "--\(boundary)\r\n"
//		guard let prefixData = prefix.data(using: .utf8) else {
//			throw "Failed to encode multi-part form boundary prefix"
//		}
//		for (key, value) in parameters {
//			body.append(prefixData)
//
//			guard let keyData = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8) else {
//				throw "Failed to encode multi-part form key \(key)"
//			}
//			guard let valueData = "\(value)\r\n".data(using: .utf8) else {
//				throw "Failed to encode multi-part form value \(value)"
//			}
//
//			body.append(keyData)
//			body.append(valueData)
//		}
//
//		body.append(prefixData)
//		guard let fileNameData = "Content-Disposition: form-data; name=\"binary\"; filename=\"binary.zip\"\r\n".data(using: .utf8) else {
//			throw "Failed to encode multi-part file form-data name"
//		}
//		guard let contentTypeData = "Content-Type: application/zip\r\n\r\n".data(using: .utf8)  else {
//			throw "Failed to encode multi-part file form-data content ty[e"
//		}
//		body.append(fileNameData)
//		body.append(contentTypeData)
//
//		body.append(data)
//		body.append("\r\n".data(using: .utf8)!)
//		body.append("--\(boundary)--".data(using: .utf8)!)
//
//		return body
//	}
	
//	func usingFileSystem() throws {
//		// Really, really, really need to know if this should be done via
//		// scp
//		let releasePath =	try Folder(path: Installer.filePath)
//			.createSubfolderIfNeeded(withName: name)
//			.createSubfolderIfNeeded(withName: version.description)
//
//		log("***".green, "Copy", "\(library.name)".bold, "\n      to", "\(releasePath.path)".bold)
//
//		let data = try library.read()
//		try releasePath.createFileIfNeeded(withName: library.name, contents: data)
//
//		log("***".green, "Update binary project specification...")
//
//		var json: [String: Any] = [:]
//		let releaseFolder = try Folder(path: Installer.filePath)
//
//		let fileName = "\(name)-\(config.xcode.stamp).json"
//		if releaseFolder.existsFile(named: fileName) {
//			json = try loadJSON(from: try releaseFolder.file(named: fileName))
//		}
//
//		let versionText = version.description
//		let releaseURL = Installer.serverURL
//			.appendingPathComponent(name)
//			.appendingPathComponent(versionText)
//			.appendingPathComponent(library.name)
//
//		json[versionText] = releaseURL.absoluteString
//		try save(json: json, toFileNamed: fileName, at: releaseFolder)
//	}
//
//	func loadJSON(from: File) throws -> [String: Any] {
//		let data = try from.read()
//		let jsonObj = try JSONSerialization.jsonObject(with: data, options: [])
//		guard let json = jsonObj as? [String: Any] else {
//			throw "Invalid Carthage Binrary Project Specification"
//		}
//		return json
//	}
//
//	func save(json: [String: Any], toFileNamed named: String, at folder: Folder) throws {
//		let file = try folder.createFileIfNeeded(withName: named)
//
//		let jsonData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
//		var text = String(data: jsonData, encoding: .utf8)!
//		text = text.replacingOccurrences(of: "\\/", with: "/")
//
//		let data = text.data(using: .utf8)!
//		try file.write(data: data)
//	}
}

//struct Uploadable: Codable {
//	var libraryVersion: String
//	var name: String
//	var xcodeVersion: String
//	var xcodeBuild: String
//	var data: String
//}
