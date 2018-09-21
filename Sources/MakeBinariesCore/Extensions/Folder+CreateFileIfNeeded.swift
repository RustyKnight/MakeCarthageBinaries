//
//  Folder+CreateFileIfNeeded.swift
//  Files
//
//  Created by Shane Whitehead on 3/9/18.
//

import Foundation
import Files

extension Folder {
	
	@discardableResult public func createFileIfNeeded(withName fileName: String, contents: String, encoding: String.Encoding) throws -> File {
		if let existingFile = try? file(named: fileName) {
			return existingFile
		}
		
		guard let data = contents.data(using: encoding) else {
			throw "Failed to encode file contents"
		}

		return try createFile(named: fileName, contents: data)
	}

}
