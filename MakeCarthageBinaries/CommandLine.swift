import Foundation
import Files

public final class CommandLineTool {
    private let arguments: [String]
    
    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }
    
    public func run() throws {
        let config = try Configuration.build(from: arguments)
        
        log("")
        log("***".blue, "\(config.xcode.stamp)")
        
        let timer = Timer()
        timer.isRunning = true
        
        var archives: [File] = []
        if config.isCurrent {
            archives = try buildCurrent(configuration: config)
        } else {
            archives = try buildAll(configuration: config)
        }
        
        Thread.sleep(forTimeInterval: 1.0)
        
        try install(archives, configuration: config)
        
        timer.isRunning = false
        log("")
        log("***".blue, "Took", "\(durationFormatter.string(from: timer.duration)!)".bold, "to build and install binraries")
    }
    
    func buildCurrent(configuration: Configuration) throws -> [File] {
        log("***".blue, "Build current project only")
        let path = Folder.current
        let archive = try build(path: path, configuration: configuration)
        //try Installer.install(library: archive, name: current.name, version: "1.0.0")
        
        return [archive]
    }
    
    func buildAll(configuration: Configuration) throws -> [File] {
        log("***".blue, "Build all sub projects")
        let current = Folder.current
        var archives: [File] = []
        for folder in current.subfolders {
            archives.append(try build(path: folder, configuration: configuration))
        }
        return archives
    }
    
    func build(path: Folder, configuration: Configuration) throws -> File {
        log("***".blue, "Build", "\(path.name)".bold)
        let builder = Builder(path: path, configuration: configuration)
        return try builder.build()
    }
    
    func install(_ archives: [File], configuration: Configuration) throws {
        for archive in archives {
            var releaseVersion: SemanticVersion?
            if let text = configuration.overrideVersion {
                releaseVersion = SemanticVersion.parse(from: text)
            } else {
                let versions = Git(path: archive.parent!).versions()
                releaseVersion = versions.first
            }
            guard let version = releaseVersion else {
                log("***".red, "\(archive.parent!.name)".green, "does not contain any version tags!")
                continue
            }
            log("*** Using tagged version".lightBlack, "\(version)".bold.lightBlack)
            try Installer.install(library: archive,
                                  name: configuration.name ?? archive.parent!.name,
                                  version: version,
                                  configuration: configuration)
        }
    }
    
}
