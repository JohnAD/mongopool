# Package

version      = "0.1.0"
author       = "John Dupuy"
description  = "MongoDB pooled client for threaded applications such as web servers"
license      = "MIT"
srcDir       = "src"
skipExt      = @["rst"]

# Dependencies

requires "nim >= 0.20.0", "bson >= 0.1.0", "scram >= 0.1.9"
