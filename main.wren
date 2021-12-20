// Dome Editor

import "graphics" for Canvas, Color
import "font" for Font
import "dome" for Platform, Window
import "input" for Keyboard
import "io" for FileSystem 

// var DefaultFont = "/usr/share/fonts/truetype/piboto/Piboto-Regular.ttf"
var DefaultFont = "/usr/share/fonts/truetype/noto/NotoMono-Regular.ttf"
var FontSize = 14
var BackgroundColor = Color.black

class Cursor {
  x { _x }
  y { _y }
  w { _w }
  h { _h }

  construct new(x, y) {
    _x = x
    _y = y
    _w = 10
    _h = FontSize
  }
}

class Text {

  // https://rosettacode.org/wiki/Category_talk:Wren-fmt
  static rjust(s, w) {
    var c = s.count
    return (w > c) ? " " * (w - c) + s : s
  }

  gutterWidth {
    var area = Canvas.getPrintArea(_lines.count.max(10).toString)
    return area.x + 4
  }

  gutterPrint(lineNumber, y) {
    var w = _lines.count.max(10).toString.count
    Canvas.print(Text.rjust(lineNumber.toString, w), 2, y, Color.white)
  }

  count {
    return _lines.count
  }

  [index] {
    return _lines[index]
  }

  construct new(text) {
    _lines = text.split("\n")
  }

  static load(fileName) {
    return Text.new(FileSystem.load(fileName))
  }

  static fit(line, width) {
    var area = Canvas.getPrintArea(line)
    
    if (area.x < width) {
      return [ line ]
    }
    
    var split = (line.count * width / area.x).floor

    var lines = Text.fit(line[0...split], width)
    lines.addAll(Text.fit(line[split...line.count], width))
    
    return lines
  }

  cursor(x, y) {
    return Cursor.new(x + gutterWidth, y) 
  }

  print(cursorX, cursorY, cursorOn) {
    var y = 6
    var lineNumber = 0

    for (line in _lines) {
      gutterPrint(lineNumber + 1, y)

      var realCursorX = cursorX.min(line.count)
      var offsetX = 0
      var offsetY = 0
      var shortLines = Text.fit(line, Canvas.width - gutterWidth - 4)
      for (shortLine in shortLines) {
        var gw = gutterWidth
        Canvas.print(shortLine, gw + 2, y, Color.white)

        if (cursorOn && lineNumber == cursorY && realCursorX >= offsetX && (realCursorX < offsetX + shortLine.count || offsetY == shortLines.count - 1 && realCursorX == line.count)) {  
          var end = realCursorX - offsetX
          //System.print("%(shortLine). len=%(shortLine.count) realX=%(realCursorX) offsX=%(offsetX) end=%(end)")
         
          var prefixArea = Canvas.getPrintArea(shortLine[0 ... end])
          Canvas.rectfill(gw + prefixArea.x, y - 2, 2, FontSize, Color.green)
        }

        y = y + FontSize + 4
        offsetY = offsetY + 1
        offsetX = offsetX + shortLine.count
      }
      lineNumber = lineNumber + 1
    }
  }
}

class Main {

  construct new() {}

  init() {
    Font.load("default", DefaultFont, FontSize)
    Font["default"].antialias = true
    Canvas.font = "default"

    _fileName = "README.md"

    _text = Text.load(_fileName)
    _x = 0
    _y = 0
    _cursorOn = true
    _debounce = 0
  }

  update() {
    if (Canvas.width != Window.width || Canvas.height != Window.height) {
      System.print("Resize -> %(Window.width), %(Window.height)")
      Canvas.resize(Window.width, Window.height, BackgroundColor)
    }
    _cursorOn = Platform.time % 2 == 1

    if (_debounce == 0) {
      if (Keyboard.isKeyDown("Up")) {
        _debounce = 10
        _cursorOn = true
        if (_y > 0) {
          _y = _y - 1
        }
      } else if (Keyboard.isKeyDown("Down")) {
        _debounce = 10
        _cursorOn = true
        if (_y < _text.count - 1) {
          _y = _y + 1
        }
      } else if (Keyboard.isKeyDown("Left")) {
        _debounce = 10
        _cursorOn = true
        if (_x > 0) {
          _x = _x - 1
        }
      } else if (Keyboard.isKeyDown("Right")) {
        _debounce = 10
        _cursorOn = true
        if (_x < _text[_y].count) {
          _x = _x + 1
        }
      }
    } else {
      _debounce = _debounce - 1
    }

  }

  draw(alpha) {
    Canvas.cls(BackgroundColor)

    var gutterWidth = _text.gutterWidth

    // Status line
    var statusY = Canvas.height - FontSize - 4
    Canvas.rectfill(0, statusY, Canvas.width, FontSize + 4, Color.darkblue)
    Canvas.print("%(_fileName) %(_y+1):%(_x+1)", 4, statusY + 6, Color.white)

    // Gutter
    Canvas.rectfill(0, 0, gutterWidth, Canvas.height - FontSize - 4, Color.darkblue)

    _text.print(_x, _y, _cursorOn)
  }
}

var Game = Main.new()
