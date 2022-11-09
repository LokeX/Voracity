import cityview

let
  fileName = "dat\\board.txt"
  board = ("board", readImage("engboard.jpg"))
  boardMouse = newMouseHandle(board,200,100)

addImage(board)
addMouseHandle(boardMouse)

var
  boardData: File
  squares:seq[string]

try:
  boardData = open(fileName,fmRead)
  while not endOfFile(boardData):
    squares.add(boardData.readLine)
    echo squares[^1]
finally:
  close(boardData)

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