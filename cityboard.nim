import cityview

let
  board = ("board", readImage("engboard.jpg"))
  boardMouse = newMouseHandle(board,200,100)

addImage(board)
addMouseHandle(boardMouse)

proc lineReadFile (filePath:string): seq[string] =
  var 
    text = open(filePath,fmRead)
  while not endOfFile(text):
    result.add(text.readLine)
  close(text)

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
  b.drawImage("board",vec2(200, 100))

proc initCityBoard*() =
  addCall(newCall("board",keyboard,mouse,draw))