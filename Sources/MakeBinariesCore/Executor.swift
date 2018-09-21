//
//  Executor.swift
//  Files
//
//  Created by Shane Whitehead on 3/9/18.
//

import Foundation

public typealias ExecutorConsumer = (Data) -> Void

public class Executor {
	public static func execute(currentDirectory: String? = nil,
											arguments args: [String],
											consumer: ExecutorConsumer? = nil) {
		let task = Process()
		task.launchPath = "/usr/bin/env"
		task.arguments = args
		if let currentDirectory = currentDirectory {
			task.currentDirectoryPath = currentDirectory
		}
		
		let pipe = Pipe()
		task.standardOutput = pipe
		task.standardError = pipe
		
		let handle = pipe.fileHandleForReading
		if let consumer = consumer {
			handle.readabilityHandler = { pipe in
				consumer(pipe.availableData)
			}
		}
		
		task.launch()
		
		if consumer == nil {
			// Consume it to be safe
			_ = pipe.fileHandleForReading.readDataToEndOfFile()
		}
		task.waitUntilExit()
	}
	
	public static func execute(currentDirectory: String? = nil,
											arguments args: String...,
		consumer: ExecutorConsumer? = nil) {
		Executor.execute(currentDirectory: currentDirectory, arguments: args.map({$0}), consumer: consumer)
		
	}
}
