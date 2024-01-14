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
        try installer.uploadTo(server: server)
    }
    
    func uploadTo(server: String) throws {
        let uploader = FileUploader()
        try uploader.upload(library: library, name: name, version: version, configuration: config, server: server)
    }
}
