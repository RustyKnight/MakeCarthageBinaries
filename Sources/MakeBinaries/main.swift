import MakeBinariesCore

let tool = CommandLineTool()

do {
    try tool.run()
} catch let error {
	log("***".red, "Failed to perform build")
	log("***".red, "\(error)")
}
