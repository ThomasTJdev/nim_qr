# Copyright 2020 - Thomas T. Jarløv

from strutils import format
from os import parentDir
from strutils import parseInt

include qr/qrcodegen


proc qrBinary*(data: string, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO): string =
  ## This returns 1 (black) and 0's (whites) representing
  ## the QR code.

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
        output = output & "1"
      else:
        output = output & "0"
      inc(x)
    inc(y)
    output = output & "\n"
  return output


proc qrRow*(data: string, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO): seq[seq[int]] =
  ## Return a seq[seq[int]] containing the QR-code. 1's is a black field,
  ## and 0's is blank field.

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


proc qrSvgGenerate(qrcodeData: ptr uint8, svgSize: int32, border: cint): string =
  ## Generates SVG code for the QR-code.

  const
    svgTag        = "<use xlink:href='#p' x='$1' y='$2'/>"
    svgClose      = "</g></svg>"

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
<rect x="0" y="0" width="$1" height="$1" fill="#ffffff"/>
<defs><rect id="p" width="$2" height="$2"/></defs>
<g fill="#000000">""".format(svgSizeCalc, svgItemSize)

  while y < size + border:
    var x: cint = -border
    svgY = 0

    while x < size + border:

      if getModule(qrcodeData, x, y):
        output.add(svgTag.format(svgX, svgY))
      else:
        discard

      inc(x)
      svgY += svgYadd

    inc(y)
    svgX += svgYadd

  return svgOpen & output & svgClose


proc qrSvgFile*(data, filename: string, size: int32 = 0, border: cint = 0, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO) =
  ## Creates a SVG file for the QR and saves it.
  ##
  ## Size should be in pixels.

  var
    qrcode: array[BUFFER_LEN_MAX, uint8]
    tempBuffer: array[BUFFER_LEN_MAX, uint8]

  if encodeText(data, addr tempBuffer[0], addr qrcode[0], eccLevel, verMin, verMax, mask, true):
    writeFile(filename, qrSvgGenerate(addr qrcode[0], size, border))


proc qrSvg*(data: string, size: int32 = 0, border: cint = 0, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO): string =
  ## Returns the SVG data
  ##
  ## Size should be in pixels.

  var
    qrcode: array[BUFFER_LEN_MAX, uint8]
    tempBuffer: array[BUFFER_LEN_MAX, uint8]

  if encodeText(data, addr tempBuffer[0], addr qrcode[0], eccLevel, verMin, verMax, mask, true):
    return qrSvgGenerate(addr qrcode[0], size, border)


proc qrPrint*(data: string, border: cint = 0, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO) =
  ## Prints the QR-code to the console with #'s.

  var
    qrcode: array[BUFFER_LEN_MAX, uint8]
    tempBuffer: array[BUFFER_LEN_MAX, uint8]

  if not encodeText(data, addr tempBuffer[0], addr qrcode[0], eccLevel, verMin, verMax, mask, true):
    return

  var
    output:string
    size: cint = getSize(addr qrcode[0])
    border: cint = border
    y: cint = -border

  while y < size + border:
    var x: cint = -border
    while x < size + border:
      if getModule(addr qrcode[0], x, y):
        output = output & "##"
      else:
        output = output & "  "
      inc(x)
    output = output & "\n"
    inc(y)
  output = output
  echo output


