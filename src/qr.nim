# Copyright 2020 - Thomas T. Jarløv

from strutils import format, countLines, splitLines, parseInt
from os import parentDir

include qr/qrcodegen


func qrBinary*(data: string, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO, fgColor = "1", bgColor = "0"): string =
  ## This returns 1 (black) and 0's (whites) representing
  ## the QR code. Each row is separated by a newline `\n`.
  ##
  ## **Example**
  ## .. code-block::nim
  ##    let qr = qrBinary("Hello world")
  ##    # qr = 1100111101\n101001010\n010101011\n101......
  ##
  assert fgColor.len > 0 and bgColor.len > 0, "fgColor and bgColor must not be empty string"
  var
    qrcode: array[BUFFER_LEN_MAX, uint8]
    tempBuffer: array[BUFFER_LEN_MAX, uint8]

  if not encodeText(data, addr tempBuffer[0], addr qrcode[0], eccLevel, verMin, verMax, mask, true):
    return

  var
    output: string
    size: cint = getSize(addr qrcode[0])
    border: cint = 0
    y: cint = -border

  while y < size + border:
    var x: cint = -border
    while x < size + border:
      if getModule(addr qrcode[0], x, y):
        output = output & fgColor
      else:
        output = output & bgColor
      inc(x)
    inc(y)
    output = output & "\n"
  return output


func qrRow*(data: string, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO): seq[seq[int]] =
  ## Return a seq[seq[int]] containing the QR-code. 1's is a black field,
  ## and 0's is blank field.
  ##
  ## **Example**
  ## .. code-block::nim
  ##    let qr = qrRow("Hello world")
  ##    # qr = @[@[0,1,1,0,1....],@[0,0,1,1,1...],@[0,1,1,1,0...
  ##

  var
    qrcode: array[BUFFER_LEN_MAX, uint8]
    tempBuffer: array[BUFFER_LEN_MAX, uint8]

  if not encodeText(data, addr tempBuffer[0], addr qrcode[0], eccLevel, verMin, verMax, mask, true):
    return

  var
    container: seq[seq[int]]
    output: seq[int]
    size: cint = getSize(addr qrcode[0])
    border: cint = 0
    y: cint = -border

  while y < size + border:
    var x: cint = -border
    while x < size + border:
      if getModule(addr qrcode[0], x, y):
        output.add(1)
      else:
        output.add(0)
      inc(x)
    inc(y)
    container.add(output)
    output = @[]
  return container


proc qrSvgGenerate(qrcodeData: ptr uint8, svgSize: int32, border: cint, fgColor = "#000000", bgColor = "#ffffff"): string =
  ## Generates SVG code for the QR-code.
  assert fgColor.len in [4, 7] and fgColor[0] == '#', "fgColor must be 4 or 7 chars Hexadecimal Color string"
  assert bgColor.len in [4, 7] and bgColor[0] == '#', "bgColor must be 4 or 7 chars Hexadecimal Color string"
  const svgClose = "</g></svg>"
  var
    qrcode: array[BUFFER_LEN_MAX, uint8]
    tempBuffer: array[BUFFER_LEN_MAX, uint8]
    output:string
    size: cint    = getSize(qrcodeData)
    border: cint  = border
    y: cint       = -border
    svgX          = (0 + parseInt($border)) / 1
    svgY          = (0 + parseInt($border)) / 1

  let
    svgSizeFinal  = if svgSize == 0: size * 10 else: svgSize
    svgYadd       = (svgSizeFinal/size)
    svgSizeCalc   = svgSizeFinal + (border * 2 * 10)
    svgItemSize   = svgSizeFinal / size
    svgOpen       = """<?xml version="1.0" encoding="utf-8"?>
<svg width="$1" height="$1" viewBox="0 0 $1 $1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ev="http://www.w3.org/2001/xml-events">
<rect x="0" y="0" width="$1" height="$1" fill="$3"/>
<defs><rect id="p" width="$2" height="$2"/></defs>
<g fill="$4">""".format(svgSizeCalc, svgItemSize, fgColor, bgColor)

  while y < size + border:
    var x: cint = -border
    svgY = 0

    while x < size + border:

      if getModule(qrcodeData, x, y):
        output.add("<use xlink:href='#p' x='" & $svgX & "' y='" & $svgY & "'/>")
      else:
        discard

      inc(x)
      svgY += svgYadd

    inc(y)
    svgX += svgYadd

  return svgOpen & output & svgClose


proc qrPbmGenerate*(data: string, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO, comment = ""): string =
  ## Generates NetPBM PBM Raster Bitmap Image code for the QR-code. https://en.wikipedia.org/wiki/Netpbm_format#PPM_example
  let
    bitmap = qrBinary(data, eccLevel, verMin, verMax, mask, fgColor = "1 ", bgColor = "0 ")
    width = bitmap.splitLines[0].len div 2  # width is (len of line0 / 2) because half are spaces.
    height = bitmap.countLines - 1          # height is countLines.
  result = (  # I bet you never knew making Raster Images was so easy uh?.
    "P1\n"                 &          # Header (standard).
    "# " & comment         & "\n" &   # Comments, metadata, arbitrary string.
    $width & " " & $height & "\n\n" & # Width Height (int).
                                      # Max Value, must be empty line in this format.
    bitmap)                           # Matrix (1 or 0), 1 black, 0 white.


template qrPbmFile*(data, filename: string, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO, comment = "") =
  writeFile(filename, qrPbmGenerate(data, eccLevel, verMin, verMax, mask, comment)) # File extension must be .pbm


template qrSvgFile*(data, filename: string, size: int32 = 0, border: cint = 0, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO) =
  ## Creates a SVG file for the QR and saves it.
  ##
  ## The `size` should be in pixels. If set to 0, the optimal size will be used
  ## based on the density.
  ##
  ## You can set the minimum and maximum size params, `verMin` and `verMax`. You
  ## can use values from 1-40.
  ##
  ## You only need to define the `data` and a `filename`. Please note there's no
  ## error checking when creating the file, you have to that yourself.
  ##
  ## **Example**
  ## .. code-block::nim
  ##    qrSvgFile("Hello world", "test.svg")
  ##

  var
    qrcode: array[BUFFER_LEN_MAX, uint8]
    tempBuffer: array[BUFFER_LEN_MAX, uint8]

  if encodeText(data, addr tempBuffer[0], addr qrcode[0], eccLevel, verMin, verMax, mask, true):
    writeFile(filename, qrSvgGenerate(addr qrcode[0], size, border))


func qrSvg*(data: string, size: int32 = 0, border: cint = 0, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO): string =
  ## Returns the SVG data
  ##
  ## The `size` should be in pixels. If set to 0, the optimal size will be used
  ## based on the density.
  ##
  ## You can set the minimum and maximum size params, `verMin` and `verMax`. You
  ## can use values from 1-40.
  ##
  ## You only need to define the `data`.
  ##
  ## **Example**
  ## .. code-block::nim
  ##    let htmlReadySvg = qrSvg("Hello world")
  ##

  var
    qrcode: array[BUFFER_LEN_MAX, uint8]
    tempBuffer: array[BUFFER_LEN_MAX, uint8]

  if encodeText(data, addr tempBuffer[0], addr qrcode[0], eccLevel, verMin, verMax, mask, true):
    return qrSvgGenerate(addr qrcode[0], size, border)


proc qrPrint*(data: string, border: cint = 0, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO, fgColor = "##", bgColor = "  ") =
  ## Prints the QR-code to the console with #'s.
  assert fgColor.len > 0 and bgColor.len > 0, "fgColor and bgColor must not be empty string"
  var
    qrcode: array[BUFFER_LEN_MAX, uint8]
    tempBuffer: array[BUFFER_LEN_MAX, uint8]

  if not encodeText(data, addr tempBuffer[0], addr qrcode[0], eccLevel, verMin, verMax, mask, true):
    return

  var
    output: string
    size: cint = getSize(addr qrcode[0])
    border: cint = border
    y: cint = -border

  while y < size + border:
    var x: cint = -border
    while x < size + border:
      if getModule(addr qrcode[0], x, y):
        output = output & fgColor
      else:
        output = output & bgColor
      inc(x)
    output = output & "\n"
    inc(y)

  echo output
