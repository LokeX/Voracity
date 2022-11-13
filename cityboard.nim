import cityview
import strutils

let
  board = newImageHandle(("board", readImage("engboard.jpg")),200,100)
  selColor = color(255,255,255,100)

addImage(board)
addMouseHandle(newMouseHandle(board))

proc lineReadFile (filePath:string): seq[string] =
  var 
    nr = 1
    text = open(filePath,fmRead)

  while not endOfFile(text):
    result.add(text.readLine&" Nr. "&nr.intToStr)
    inc nr
  close(text)

var
  squares = lineReadFile("dat\\board.txt")

echo squares,": ",squares.len

proc makeAreas(): array[1..60,Area] =
  for i in 0..17:
    result[37+i] = (420+(i*43),170,35,100)
    result[7+i] = (420+(i*43),790,35,100)
    if i < 12:
      result[25+i] = (270,272+(i*43),100,35)
      if i < 6:
        result[55+i] = (1230,272+(i*43),100,35)
      else:
        result[1+(i-6)] = (1230,272+(i*43),100,35)

var
  areas = makeAreas()

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    if mouseOn(board):
      playSound("carstart-1")

proc draw (b:var Boxy) =
  b.drawImage("board",vec2(200, 100))
  for area in areas:
    b.drawRect(area.toRect(),selColor)

proc initCityBoard*() =
  addCall(newCall("board",keyboard,mouse,draw))