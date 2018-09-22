import MakeBinariesCore
import Foundation

setenv("CFNETWORK_DIAGNOSTICS", "3", 1);

let tool = CommandLineTool()

do {
    try tool.run()
} catch let error {
	log("***".red, "Failed to perform build")
	log("***".red, "\(error)")
}
