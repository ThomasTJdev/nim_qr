# Package

version       = "1.0.0"
author        = "Thomas T. Jarløv"
description   = "QR-code tools. Generate SVG-files with QR-codes, get QR-code sizes, etc."
license       = "MIT"
srcDir        = "src"

# Dependencies

requires: "nim >= 1.0.6"

task setup, "Generating C-code":
  exec "gcc -c -o src/qr/include/qrcodegen.o src/qr/include/qrcodegen.c"
  exec "gcc -o src/qr/include/qrcodegen.so -shared src/qr/include/qrcodegen.o"

before install:
  setupTask()