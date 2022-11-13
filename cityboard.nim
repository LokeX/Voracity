import cityview
import strutils
import sequtils

let
  board = newImageHandle(("board", readImage("engboard.jpg")),200,100)
  selColor = color(255,255,255,100)

addImage(board)
addMouseHandle(newMouseHandle(board))

proc squareNames (filePath:string): seq[string] =
  var 
    nr = 1
    text = open(filePath,fmRead)

  while not endOfFile(text):
    result.add(text.readLine&" Nr. "&nr.intToStr)
    inc nr
  close(text)

proc makeAreaHandles(names:seq[string],areas:openArray[Area]): array[1..60,AreaHandle] =
  let 
    squares = zip(names,areas)
  var i = 0
  for square in squares:
    inc i
    result[i] = newAreaHandle(square)

func makeAreas(): array[1..60,Area] =
  for i in 0..17:
    result[37+i] = (420+(i*43),170,35,100)
    result[24-i] = (420+(i*43),790,35,100)
    if i < 12:
      result[36-i] = (270,272+(i*43),100,35)
      if i < 6:
        result[55+i] = (1230,272+(i*43),100,35)
      else:
        result[1+(i-6)] = (1230,272+(i*43),100,35)

var
  areas = makeAreaHandles(squareNames("dat\\board.txt"),makeAreas())

for areaHandle in areas:
  addMouseHandle(newMouseHandle(areaHandle))

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    if mouseOn(board):
      playSound("carstart-1")

proc draw (b:var Boxy) =
  b.drawImage("board",vec2(200, 100))
  for handle in areas:
    b.drawRect(handle.area.toRect(),selColor)

proc initCityBoard*() =
  addCall(newCall("board",keyboard,mouse,draw))