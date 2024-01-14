# MakeCarthageBinaries

A CLI utility to factility the building of Carthage based libraries and uploading those libraries to file server.

This would the facilitate the deployment of the binaries directly, rather then relying on Carthage to re-build them each time.  This makes the builds faster and more stable.

This was also written around a time when Swift ABI was not yet stable, so each change in Swift would require the libraries to be re-built.

Currently the project is broken due to changes in the `ArgumentParser` workflows.
