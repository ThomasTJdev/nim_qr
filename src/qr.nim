# Copyright 2020 - Thomas T. Jarløv

from strutils import `%`

include qr/qrcodegen


func qrBinary*(data: string, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO, fgColor = "1", bgColor = "0"): string {.noinit.} =
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
    return ""

  var
    size: cint = getSize(addr qrcode[0])
    border: cint = 0
    y: cint = -border

  # This is approx the size of result string for single memory alloc, if its wrong still no error.
  result = newStringOfCap((border + size + border + 1) * (border + size + border)) # X+1 * Y

  while y < size + border:
    var x: cint = -border
    while x < size + border:
      if getModule(addr qrcode[0], x, y):
        result = result & fgColor
      else:
        result = result & bgColor
      inc(x)
    inc(y)
    result = result & '\n'


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
    result.add output
    output = @[]


func qrSvgGenerate(qrcodeData: ptr uint8, svgSize: int32, border: cint, fgColor: static string = "#000000", bgColor: static string = "#ffffff"): string {.noinit.} =
  ## Generates SVG code for the QR-code.
  assert fgColor.len in [4, 7] and fgColor[0] == '#', "fgColor must be 4 or 7 chars Hexadecimal Color string"
  assert bgColor.len in [4, 7] and bgColor[0] == '#', "bgColor must be 4 or 7 chars Hexadecimal Color string"
  var
    output: string
    size: cint   = getSize(qrcodeData)
    border: cint = border
    y: cint      = -border
    svgX         = border / 1
    svgY         = border / 1

  let
    svgSizeFinal = if svgSize == 0: size * 10 else: svgSize
    svgSizeCalc  = svgSizeFinal + (border * 2 * 10)
    svgItemSize  = svgSizeFinal / size

  while y < size + border:
    var x: cint = -border
    svgY = 0

    while x < size + border:

      if getModule(qrcodeData, x, y):
        output.add("<use xlink:href='#p' x='" & $svgX.int & "' y='" & $svgY.int & "'/>")

      inc(x)
      svgY += svgItemSize

    inc(y)
    svgX += svgItemSize

  # bgColor and fgColor is formatted at compile-time. Sizes and data is formatted at run-time.
  result = static("""<?xml version="1.0" encoding="utf-8"?><svg width="$$1" height="$$1" viewBox="0 0 $$1 $$1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ev="http://www.w3.org/2001/xml-events"><rect x="0" y="0" width="$$1" height="$$1" fill="$1"/><defs><rect id="p" width="$$2" height="$$2"/></defs><g fill="$2">$$3</g></svg>""" % [bgColor, fgColor]
    ) % [$svgSizeCalc, $svgItemSize, output]


func qrPbmGenerate*(data: string, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO): string {.noinit.} =
  ## Generates NetPBM PBM Raster Bitmap Image code for the QR-code. https://en.wikipedia.org/wiki/Netpbm_format#PPM_example
  let
    matrix = qrRow(data, eccLevel, verMin, verMax, mask)
    width = matrix[0].len
    height = matrix.len
  result = "P1\n#\n" & $width & ' ' & $height & '\n' & '\n'
  for line in matrix:   # Iterate seq[seq[int]] and generate multiline string
    for column in line: # Format is very simple human readable
      result.add(if column == 1: '1' else: '0')
      result.add ' '
    result.add '\n'


template qrPbmFile*(data, filename: string, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO) =
  assert filename.len > 0, "filename must not be empty string"
  writeFile(filename & ".pbm", qrPbmGenerate(data, eccLevel, verMin, verMax, mask))


func qrXpmGenerate*(data: string, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO): string {.noinit.} =
  ## Generates XPM Raster Bitmap Image code for the QR-code. https://en.wikipedia.org/wiki/X_PixMap
  ## Output image is small 25x25 pixels, but can be scaled up 999% because is not compressed.
  let
    matrix = qrRow(data, eccLevel, verMin, verMax, mask)
    width = matrix[0].len
    height = matrix.len
  result = "/* XPM */\nstatic char *qrcode_xpm[] = {\n \"" & $width & ' ' & $height & " 2 1\",\n \"0 c #fff\",\n \"1 c #000\",\n"
  for line in matrix:   # Iterate seq[seq[int]] and generate multiline string
    result.add ' '      # '1' is black, '0' is white on the string
    result.add '"'      # 1 line per row, 1 char per column
    for column in line: # Format is very simple human readable
      result.add(if column == 1: '1' else: '0')
    result.add '"'
    result.add ','
    result.add '\n'
  result.add '}'
  result.add ';'
  result.add '\n'


template qrXpmFile*(data, filename: string, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO) =
  assert filename.len > 0, "filename must not be empty string"
  writeFile(filename & ".xpm", qrXpmGenerate(data, eccLevel, verMin, verMax, mask))


template qrSvgFile*(data, filename: string, size = 0.Natural, border = 0.Natural, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO) =
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
  assert filename.len > 0, "filename must not be empty string"
  var
    qrcode: array[BUFFER_LEN_MAX, uint8]
    tempBuffer: array[BUFFER_LEN_MAX, uint8]

  if encodeText(data, addr tempBuffer[0], addr qrcode[0], eccLevel, verMin, verMax, mask, true):
    writeFile(filename, qrSvgGenerate(addr qrcode[0], size.int32, border.cint))


func qrSvg*(data: string, size = 0.Natural, border = 0.Natural, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO): string {.noinit.} =
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
  result =
    if encodeText(data, addr tempBuffer[0], addr qrcode[0], eccLevel, verMin, verMax, mask, true):
      qrSvgGenerate(addr qrcode[0], size.int32, border.cint)
    else:
      ""


proc qrPrint*(data: string, border = 0.Natural, eccLevel = Ecc_Medium, verMin: cint = VERSION_MIN, verMax: cint = VERSION_MAX, mask = Mask_AUTO, fgColor = "##", bgColor = "  ") =
  ## Prints the QR-code to the console with #'s.
  assert fgColor.len > 0 and bgColor.len > 0, "fgColor and bgColor must not be empty string"
  var
    qrcode: array[BUFFER_LEN_MAX, uint8]
    tempBuffer: array[BUFFER_LEN_MAX, uint8]

  if not encodeText(data, addr tempBuffer[0], addr qrcode[0], eccLevel, verMin, verMax, mask, true):
    return

  let
    size = getSize(addr qrcode[0]).cint
    border = border.cint
  var
    output = newStringOfCap((border + size + border + 1) * (border + size + border)) # X+1 * Y
    y: cint = -border

  while y < size + border:
    var x: cint = -border
    while x < size + border:
      if getModule(addr qrcode[0], x, y):
        output = output & fgColor
      else:
        output = output & bgColor
      inc(x)
    output.add '\n'
    inc(y)

  echo output


when isMainModule: # Too verbose to be runnableExamples
  qrPrint("0123456789 abcdef")

  echo qrPbmGenerate("0123456789 abcdef")

  echo qrXpmGenerate("0123456789 abcdef")

  qrSvgFile("0123456789 abcdef", "out.svg")

  qrXpmFile("0123456789 abcdef", "out.xpm")

  qrPbmFile("0123456789 abcdef", "out.pbm")

  doAssert qrBinary("0123456789 abcdef") == """1111111011100101001111111
1000001000011111001000001
1011101000100100101011101
1011101001111011001011101
1011101010100000101011101
1000001011111001101000001
1111111010101010101111111
0000000001011011100000000
0111111100010001000110001
0011000010000110110001010
0100011001001111000001101
0011010001100101111011011
1000111000000011001110101
1000110011000100100001010
1000101000010111101110101
1001100011111000001101001
1001111111001011111110101
0000000011101001100010010
1111111011100010101011001
1000001011100010100011011
1011101011000101111110101
1011101010011111111110011
1011101011001011000000001
1000001010110111101011001
1111111000001110011100111
"""

  doAssert qrRow("0123456789 abcdef") == @[
    @[1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1],
    @[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1],
    @[1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1],
    @[1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1],
    @[1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1],
    @[1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 1],
    @[1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1],
    @[0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    @[0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1],
    @[0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 0, 1, 0],
    @[0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1],
    @[0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1],
    @[1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0, 1, 0, 1],
    @[1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0],
    @[1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1],
    @[1, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1],
    @[1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1],
    @[0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0],
    @[1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1],
    @[1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 0, 1, 1],
    @[1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1],
    @[1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1],
    @[1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    @[1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1],
    @[1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1]
  ]
