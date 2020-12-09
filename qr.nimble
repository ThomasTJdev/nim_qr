# Package

version       = "1.5.0"
author        = "Thomas T. Jarløv"
description   = "QR-code tools. Generate SVG-files with QR-codes, get QR-code sizes, etc."
license       = "MIT"
srcDir        = "src"

# Dependencies

requires: "nim >= 1.4.0"

task setup, "Generating C-code":
  exec "gcc -c -fPIC -o src/qr/qrcodegen.o src/qr/qrcodegen.c"
  exec "gcc -o src/qr/qrcodegen.so -shared -fPIC src/qr/qrcodegen.o"
  # ERROR: /usr/bin/ld: qrcodegen.o: relocation R_X86_64_PC32 against qrcodegen_encodeSegmentsAdvanced cant be used making shared object; recompile with -fPIC
  try:
    cpFile "src/qr/qrcodegen.so", "/usr/lib/qrcodegen.so"
  except:
    echo "Failed to install dynamic library at /usr/lib/qrcodegen.so"


before install:
  setupTask()
