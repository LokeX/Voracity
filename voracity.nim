import cityview
import citytext
import citydice
import os

let
  fileName = "dat\\board.txt"
  board: ImageName = ("board", readImage("engboard.jpg"))
  bg: ImageName = ("bg", readImage("bggreen.png"))
  boardMouse = newMouseHandle(board,200,100)

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

addImage(bg)
addImage(board)
addMouseHandle(boardMouse)

proc keyboard (k:KeyEvent) =
  if k.button == ButtonUnknown:
    echo "Rune: ",k.rune

proc mouse (m:MouseEvent) =
  if mouseClicked(m.keyState):
    echo "pos: ",m.pos
    if mouseOn(board):
      playSound("carstart-1")

proc draw (b:var Boxy) =
  b.drawImage("bg", rect = rect(vec2(0, 0), window.size.vec2))
  b.drawText("text3",800,25,mouseOn())
  b.drawImage("board", pos = vec2(200, 100))
#  b.drawRect(rect(vec2(300,300),vec2(500,500)),color(255,255,255,150))

addCall(newCall("voracity",keyboard,mouse,draw))
initDice()
echo "nr of recievers: ",calls.len()
echo "nr of mouse handles:",mouseHandles.len()

while not window.closeRequested:
  sleep(30)
  pollEvents()