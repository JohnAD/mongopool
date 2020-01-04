# Package

version      = "1.0.1"
author       = "John Dupuy"
description  = "MongoDB pooled client for threaded applications such as web servers"
license      = "MIT"
srcDir       = "src"
skipExt      = @["rst"]

# Dependencies

requires "nim >= 1.0.0", "bson >= 1.1.2", "scram >= 0.1.9"
