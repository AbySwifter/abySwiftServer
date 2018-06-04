// Generated automatically by Perfect Assistant Application
// Date: 2017-09-20 19:30:47 +0000
import PackageDescription

let versions = Version(0,0,0)..<Version(10,0,0)

let urls = [
    "https://github.com/PerfectlySoft/Perfect-HTTPServer.git",
    "https://github.com/PerfectlySoft/Perfect-Mustache.git",
    "https://github.com/PerfectlySoft/Perfect-MySQL.git"
]

let package = Package(
	name: "PerfectTemplate",
	targets: [],
    dependencies: urls.map { .Package(url: $0, versions: versions) }
)
