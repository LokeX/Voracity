import cityview

let
  board = ("board", readImage("engboard.jpg"))
  boardMouse = newMouseHandle(board,200,100)

addImage(board)
addMouseHandle(boardMouse)

proc lineReadFile (filePath:string): seq[string] =
  var 
    textFile: File
  try:
    textFile = open(filePath,fmRead)
    while not endOfFile(textFile):
      result.add(textFile.readLine)
  finally:
    close(textFile)

var
  squares = lineReadFile("dat\\board.txt")

echo squares

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    if mouseOn(board):
      playSound("carstart-1")

proc draw (b:var Boxy) =
  b.drawImage("board", pos = vec2(200, 100))

proc initCityBoard*() =
  addCall(newCall("board",keyboard,mouse,draw))