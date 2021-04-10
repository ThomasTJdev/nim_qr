# Package

version       = "1.3.1"
author        = "Thomas T. Jarløv"
description   = "QR-code tools. Generate SVG-files with QR-codes, get QR-code sizes, etc."
license       = "MIT"
srcDir        = "src"

# Dependencies
requires: "nim >= 1.4.0"


import os

task setup, "Generating C-code":
  const ext = when defined(windows): ".dll" elif defined(macosx): ".dylib" else: ".so"
  const path = when defined(windows): "C:\\Windows\\System32" else: "/usr/lib"
  doAssert dirExists(path), "Error directory not found: " & path # Extremely unlikely

  if not fileExists(path / "qrcodegen" & ext):
    exec "gcc -c -fPIC -o src/qr/qrcodegen.o src/qr/qrcodegen.c"
    exec "gcc -shared -fPIC src/qr/qrcodegen.o -o src/qr/qrcodegen" & ext
    # ERROR: /usr/bin/ld: qrcodegen.o: relocation R_X86_64_PC32 against qrcodegen_encodeSegmentsAdvanced cant be used making shared object; recompile with -fPIC
    try:
      cpFile "src/qr/qrcodegen" & ext, path / "qrcodegen" & ext
    except:
      echo "Failed to install dynamic library: " & path / "qrcodegen" & ext
      echo "Please copy the file src/qr/qrcodegen" & ext & " to " & path / "qrcodegen" & ext
      when defined(windows):
        echo "and reboot the computer before using the qr module."
  else:
    echo "Dynamic library already exists: " & path / "qrcodegen" & ext


before install:
  setupTask()
