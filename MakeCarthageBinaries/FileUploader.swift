//
//  FileUploader.swift
//  Basic
//
//  Created by Shane Whitehead on 22/9/18.
//

import Foundation
import Files

class FileUploader: NSObject {
    
    let semaphore = DispatchSemaphore(value: 0)
    var failed = true
    
    var previousProgress = -1
    
    func upload(library: File,
                name: String,
                version: SemanticVersion,
                configuration config: Configuration,
                server: String) throws {
        
        log("***".green, "Preparing to upload", "\(library.name)".bold, "...")
        
        let timer = Timer()
        timer.isRunning = true
        
        log("... read library archive".lightBlack)
        let data = try library.read()
        
        let libraryName = config.name ?? library.parent!.name
        
        guard let url = URL(string: server) else {
            throw "Invalid URL"
        }
        log("... make request".lightBlack)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let param = [
            "name": libraryName,
            "version": version.description,
            "xcodeVersion": config.xcode.version,
            "xcodeBuild": config.xcode.build,
            "tag": config.tag
        ]
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        log("... create body".lightBlack)
        let body = try createBody(parameters: param, boundary: boundary, data: data)
        request.httpBody = body
        
        let URLSessionConfig = URLSessionConfiguration.default
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        let session = URLSession(configuration: URLSessionConfig, delegate: self, delegateQueue: queue)
        log("... create task".lightBlack)
        //		let task = session.dataTask(with: request)
        
        let task = session.uploadTask(withStreamedRequest: request)
        
        log("... resume task".lightBlack)
        previousProgress = -1
        task.resume()
        
        //
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
        log("***".green, "Uploading", "\(library.name)".bold, "...")
        semaphore.wait()
        
        timer.isRunning = false
        guard !failed else {
            return
        }
        log("***".green,
            "Took",
            "\(durationFormatter.string(from: timer.duration)!)".bold,
            "to upload",
            "\(library.name)".bold)
        
    }
    
    func createBody(parameters: [String: String], boundary: String, data: Data) throws -> Data {
        var body = Data()
        let prefix = "--\(boundary)\r\n"
        guard let prefixData = prefix.data(using: .utf8) else {
            throw "Failed to encode multi-part form boundary prefix"
        }
        for (key, value) in parameters {
            body.append(prefixData)
            
            guard let keyData = "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8) else {
                throw "Failed to encode multi-part form key \(key)"
            }
            guard let valueData = "\(value)\r\n".data(using: .utf8) else {
                throw "Failed to encode multi-part form value \(value)"
            }
            
            body.append(keyData)
            body.append(valueData)
        }
        
        body.append(prefixData)
        guard let fileNameData = "Content-Disposition: form-data; name=\"binary\"; filename=\"binary.zip\"\r\n".data(using: .utf8) else {
            throw "Failed to encode multi-part file form-data name"
        }
        guard let contentTypeData = "Content-Type: application/zip\r\n\r\n".data(using: .utf8)  else {
            throw "Failed to encode multi-part file form-data content ty[e"
        }
        body.append(fileNameData)
        body.append(contentTypeData)
        
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--".data(using: .utf8)!)
        
        return body
    }
    
}

extension FileUploader: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        //		log("--- didReceive response \(response)".lightBlack)
        if let httpResponse = response as? HTTPURLResponse {
            let statusCode = httpResponse.statusCode
            log("***".blue, "Server responded with", "\(statusCode) - \(HTTPURLResponse.localizedString(forStatusCode: statusCode))".bold)
        }
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        //		log("--- didCompleteWithError".lightBlack)
        defer {
            semaphore.signal()
        }
        if let error = error {
            failed = true
            log("***".red, "\(error)")
            return
        }
        failed = false
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        //log("--- didSendBodyData \(bytesSent); \(totalBytesSent); \(totalBytesExpectedToSend)".lightBlack)
        
        let progress = Int((Double(totalBytesSent) / Double(totalBytesExpectedToSend)) * 100.0)
        guard progress % 5 == 0 && progress != previousProgress else {
            return
        }
        previousProgress = progress
        log("...\(progress)%".lightBlack)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        log("--- didReceive".lightBlack)
    }
    
}
